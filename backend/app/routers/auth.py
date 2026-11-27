
from typing import Annotated
from uuid import UUID
from app.core.dependencies import get_current_user
from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import InvalidTokenError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.tokens import decode_access_token
from app.models.user import User
from app.schemas.auth import (
    AuthResponse,
    PhoneLoginRequest,
    EmailLoginRequest,
    EmailRegistrationRequest,
    EmailResendRequest,
    EmailVerificationRequest,
    GoogleSignInRequest,
    RefreshRequest,
    UserPublic,
    PhoneRegistrationRequest,
    PhoneVerificationRequest,
    VerificationPendingResponse,
)
from app.services.auth_service import (
    AccountInactive,
    PhoneAlreadyRegistered,
    InvalidPhoneVerification,
    register_phone_user,
    verify_phone_registration,
    EmailAlreadyRegistered,
    EmailDeliveryError,
    EmailResendTooSoon,
    EmailVerificationRequired,
    InvalidCredentials,
    InvalidEmailVerificationCode,
    InvalidRefreshToken,
    GoogleIdentityAlreadyLinked,
    link_google_identity,
    RefreshTokenReuseDetected,
    authenticate_user,
    authenticate_phone_user,
    register_user,
    resend_email_verification,
    revoke_refresh_token,
    rotate_refresh_token,
    verify_email_registration,
    PhoneVerificationRequired,
    GoogleAccountAlreadyExists,
    InvalidGoogleAuthentication,
    GoogleAuthenticationNotConfigured,
    authenticate_google_user,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])
bearer_scheme = HTTPBearer(auto_error=False)

DbSession = Annotated[AsyncSession, Depends(get_db)]


def _uses_cookie(request: Request) -> bool:
    return request.headers.get("X-Auth-Transport", "").lower() == "cookie"


def _set_refresh_cookie(response: Response, token: str) -> None:
    response.set_cookie(
        key="aethera_refresh",
        value=token,
        httponly=True,
        secure=settings.app_env != "development",
        samesite="lax",
        max_age=settings.refresh_token_expire_days * 24 * 60 * 60,
        path="/auth",
    )


def _clear_refresh_cookie(response: Response) -> None:
    response.delete_cookie(
        key="aethera_refresh",
        path="/auth",
        httponly=True,
        secure=settings.app_env != "development",
        samesite="lax",
    )


def _auth_response(
    user: User,
    access_token: str,
    refresh_token: str,
    cookie_transport: bool,
) -> AuthResponse:
    return AuthResponse(
        access_token=access_token,
        expires_in=settings.access_token_expire_minutes * 60,
        refresh_token=None if cookie_transport else refresh_token,
        user=UserPublic.model_validate(user),
    )


@router.post(
    "/register",
    response_model=VerificationPendingResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def sign_up(
    payload: EmailRegistrationRequest,
    db: DbSession,
):
    try:
        await register_user(
            db,
            full_name=payload.full_name,
            email=str(payload.email),
            password=payload.password,
            preferred_language=payload.preferred_language,
            role=payload.role,
        )
    except EmailAlreadyRegistered:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        ) from None
    except EmailDeliveryError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="We could not send the verification email. Please try resending the code.",
        ) from None

    return VerificationPendingResponse(
        message="Registration received. Check your email for the verification code."
    )

@router.post(
    "/register-phone",
    response_model=VerificationPendingResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def sign_up_phone(
    payload: PhoneRegistrationRequest,
    db: DbSession,
):
    try:
        await register_phone_user(
            db,
            full_name=payload.full_name,
            phone_number=payload.phone_number,
            password=payload.password,
            preferred_language=payload.preferred_language,
            role=payload.role,
        )
    except PhoneAlreadyRegistered:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this phone number already exists.",
        ) from None

    return VerificationPendingResponse(
        message="Registration received. Verify your phone number to activate your account."
    )
@router.post("/verify-phone", response_model=AuthResponse)
async def verify_phone(
    payload: PhoneVerificationRequest,
    request: Request,
    response: Response,
    db: DbSession,
):
    try:
        user, access_token, refresh_token = await verify_phone_registration(
            db,
            phone_number=payload.phone_number,
            firebase_id_token=payload.firebase_id_token,
        )
    except InvalidPhoneVerification:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phone verification failed. Please verify your phone number and try again.",
        ) from None

    cookie_transport = _uses_cookie(request)

    if cookie_transport:
        _set_refresh_cookie(response, refresh_token)

    return _auth_response(user, access_token, refresh_token, cookie_transport)
@router.post("/verify-email", response_model=AuthResponse)
async def verify_email(
    payload: EmailVerificationRequest,
    request: Request,
    response: Response,
    db: DbSession,
):
    try:
        user, access_token, refresh_token = await verify_email_registration(
            db,
            email=str(payload.email),
            code=payload.code,
        )
    except InvalidEmailVerificationCode:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The verification code is invalid or expired.",
        ) from None

    cookie_transport = _uses_cookie(request)

    if cookie_transport:
        _set_refresh_cookie(response, refresh_token)

    return _auth_response(user, access_token, refresh_token, cookie_transport)


@router.post(
    "/resend-verification",
    response_model=VerificationPendingResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def resend_verification(
    payload: EmailResendRequest,
    db: DbSession,
):
    try:
        await resend_email_verification(
            db,
            email=str(payload.email),
        )
    except EmailResendTooSoon:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Please wait before requesting another verification code.",
        ) from None
    except EmailDeliveryError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="We could not send the verification email. Please try again later.",
        ) from None
    except InvalidEmailVerificationCode:
        # Keep the response generic to avoid revealing account status.
        pass

    return VerificationPendingResponse(
        message="If this account requires verification, a code will be sent to its email address."
    )

@router.post("/login-phone", response_model=AuthResponse)
async def sign_in_phone(
    payload: PhoneLoginRequest,
    request: Request,
    response: Response,
    db: DbSession,
):
    try:
        user, access_token, refresh_token = await authenticate_phone_user(
            db,
            phone_number=payload.phone_number,
            password=payload.password,
        )
    except InvalidCredentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or password.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from None
    except PhoneVerificationRequired:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Please verify your phone number before signing in.",
        ) from None
    except AccountInactive:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account is inactive.",
        ) from None

    cookie_transport = _uses_cookie(request)

    if cookie_transport:
        _set_refresh_cookie(response, refresh_token)

    return _auth_response(user, access_token, refresh_token, cookie_transport)
@router.post("/google", response_model=AuthResponse)
async def sign_in_google(
    payload: GoogleSignInRequest,
    request: Request,
    response: Response,
    db: DbSession,
):
    try:
        user, access_token, refresh_token = await authenticate_google_user(
            db,
            firebase_id_token=payload.id_token,
        )
    except GoogleAccountAlreadyExists:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "An account with this email already exists. "
                "Please sign in using your existing method before linking Google."
            ),
        ) from None
    except GoogleAuthenticationNotConfigured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Google sign-in is not configured on the API. Set a valid "
                "FIREBASE_CREDENTIALS_PATH to a Firebase Admin service-account file."
            ),
        ) from None
    except InvalidGoogleAuthentication:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google authentication failed. Please try again.",
        ) from None

    cookie_transport = _uses_cookie(request)

    if cookie_transport:
        _set_refresh_cookie(response, refresh_token)

    return _auth_response(user, access_token, refresh_token, cookie_transport)
@router.post("/login", response_model=AuthResponse)
async def sign_in(
    payload: EmailLoginRequest,
    request: Request,
    response: Response,
    db: DbSession,
):
    try:
        user, access_token, refresh_token = await authenticate_user(
            db,
            email=str(payload.email),
            password=payload.password,
        )
    except InvalidCredentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from None
    except EmailVerificationRequired:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Please verify your email address before signing in.",
        ) from None
    except AccountInactive:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account is inactive.",
        ) from None

    cookie_transport = _uses_cookie(request)

    if cookie_transport:
        _set_refresh_cookie(response, refresh_token)

    return _auth_response(user, access_token, refresh_token, cookie_transport)


@router.post("/refresh", response_model=AuthResponse)
async def refresh_access_token(
    payload: RefreshRequest,
    request: Request,
    response: Response,
    db: DbSession,
):
    raw_token = payload.refresh_token or request.cookies.get("aethera_refresh")

    if not raw_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token is required.",
        )

    try:
        user, access_token, new_refresh_token = await rotate_refresh_token(
            db, raw_token
        )
    except (InvalidRefreshToken, RefreshTokenReuseDetected):
        _clear_refresh_cookie(response)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token is invalid or expired. Please sign in again.",
        ) from None
    except AccountInactive:
        _clear_refresh_cookie(response)
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account is inactive.",
        ) from None

    cookie_transport = (
        payload.refresh_token is None
        and bool(request.cookies.get("aethera_refresh"))
    )

    if cookie_transport:
        _set_refresh_cookie(response, new_refresh_token)

    return _auth_response(
        user, access_token, new_refresh_token, cookie_transport
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def sign_out(
    payload: RefreshRequest,
    request: Request,
    response: Response,
    db: DbSession,
):
    raw_token = payload.refresh_token or request.cookies.get("aethera_refresh")

    if raw_token:
        await revoke_refresh_token(db, raw_token)

    _clear_refresh_cookie(response)
    response.status_code = status.HTTP_204_NO_CONTENT
    return response





@router.post("/link-google", response_model=UserPublic)
async def link_google_account(
    payload: GoogleSignInRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: DbSession,
):
    try:
        user = await link_google_identity(
            db,
            user=current_user,
            firebase_id_token=payload.id_token,
        )
    except GoogleIdentityAlreadyLinked:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This Google account is already linked to your AETHERA account.",
        ) from None
    except GoogleAccountAlreadyExists:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This Google identity belongs to another AETHERA account.",
        ) from None
    except InvalidGoogleAuthentication:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google identity verification failed.",
        ) from None

    return UserPublic.model_validate(user)
@router.get("/me", response_model=UserPublic)
async def get_my_profile(
    current_user: Annotated[User, Depends(get_current_user)],
):
    return current_user
