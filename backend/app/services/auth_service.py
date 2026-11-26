
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.refresh_tokens import generate_refresh_token, hash_refresh_token
from app.core.security import hash_password, verify_password
from app.core.tokens import create_access_token
from app.core.firebase_auth import (
    FirebaseTokenError,
    verify_phone_identity,
    verify_google_identity,
)
from app.models.pending_verification import PendingVerification
from app.models.refresh_session import RefreshSession
from app.models.user import User
from app.models.auth_identity import AuthIdentity
from app.services.email_service import send_verification_email
from app.services.otp_service import (
    email_otp_expiration,
    generate_email_otp,
    hash_email_otp,
    verify_email_otp,
)


# ---------------------------------------------------------------------
# Authentication exceptions
# ---------------------------------------------------------------------

class EmailAlreadyRegistered(Exception):
    pass


class InvalidCredentials(Exception):
    pass


class InvalidRefreshToken(Exception):
    pass


class RefreshTokenReuseDetected(Exception):
    pass


class AccountInactive(Exception):
    pass


class EmailVerificationRequired(Exception):
    pass


class InvalidEmailVerificationCode(Exception):
    pass


class EmailDeliveryError(Exception):
    pass


class EmailResendTooSoon(Exception):
    pass


class PhoneAlreadyRegistered(Exception):
    pass


class PhoneVerificationRequired(Exception):
    pass


class InvalidPhoneVerification(Exception):
    pass


class GoogleAccountAlreadyExists(Exception):
    pass


class InvalidGoogleAuthentication(Exception):
    pass


class GoogleIdentityAlreadyLinked(Exception):
    pass


# ---------------------------------------------------------------------
# Refresh session helper
# ---------------------------------------------------------------------

def _new_session(
    user_id: uuid.UUID,
    family_id: uuid.UUID | None = None,
) -> tuple[RefreshSession, str]:
    raw_token = generate_refresh_token()

    session = RefreshSession(
        user_id=user_id,
        family_id=family_id or uuid.uuid4(),
        token_hash=hash_refresh_token(raw_token),
        expires_at=datetime.now(timezone.utc)
        + timedelta(days=settings.refresh_token_expire_days),
    )

    return session, raw_token


# ---------------------------------------------------------------------
# Email registration
# ---------------------------------------------------------------------

async def register_user(
    db: AsyncSession,
    *,
    full_name: str,
    role: str = "farmer",
    email: str,
    password: str,
    preferred_language: str = "en",
) -> PendingVerification:
    normalized_email = email.strip().lower()

    # An actual account, verified or not, already owns this email.
    existing_user = await db.scalar(
        select(User.id).where(User.email == normalized_email)
    )

    if existing_user is not None:
        raise EmailAlreadyRegistered

    now = datetime.now(timezone.utc)

    try:
        # Check whether a previous pending registration exists.
        existing_pending = await db.scalar(
            select(PendingVerification)
            .where(PendingVerification.email == normalized_email)
            .order_by(PendingVerification.created_at.desc())
            .with_for_update()
        )

        if existing_pending is not None:
            expiry = existing_pending.expires_at

            if expiry.tzinfo is None:
                expiry = expiry.replace(tzinfo=timezone.utc)

            if expiry > now:
                raise EmailAlreadyRegistered

            # Expired pending registrations can be replaced.
            await db.delete(existing_pending)
            await db.flush()

        code = generate_email_otp()

        pending = PendingVerification(
            user_id=None,
            email=normalized_email,
            role=role,
            full_name=full_name.strip(),
            password_hash=hash_password(password),
            preferred_language=preferred_language,
            code_hash=hash_email_otp(code),
            expires_at=email_otp_expiration(),
            attempts=0,
            created_at=now,
        )

        db.add(pending)
        await db.flush()

        # Send the email before committing the pending registration.
        # No User record is created here.
        await send_verification_email(
            recipient_email=normalized_email,
            code=code,
            language=preferred_language,
        )

        await db.commit()
        await db.refresh(pending)

        return pending

    except EmailAlreadyRegistered:
        await db.rollback()
        raise

    except IntegrityError:
        await db.rollback()
        raise EmailAlreadyRegistered from None

    except Exception as exc:
        await db.rollback()
        raise EmailDeliveryError from exc


# ---------------------------------------------------------------------
# Phone registration
# ---------------------------------------------------------------------

async def register_phone_user(
    db: AsyncSession,
    *,
    full_name: str,
    role: str = "farmer",
    phone_number: str,
    password: str,
    preferred_language: str = "en",
) -> User:
    normalized_phone = phone_number.strip()

    existing = await db.scalar(
        select(User.id).where(User.phone_number == normalized_phone)
    )

    if existing is not None:
        raise PhoneAlreadyRegistered

    user = User(
        full_name=full_name.strip(),
        phone_number=normalized_phone,
        password_hash=hash_password(password),
        auth_provider="phone",
        role=role,
        expert_approval_status=(
            "pending" if role == "expert" else "not_applicable"
        ),
        is_active=True,
        is_verified=False,
        preferred_language=preferred_language,
    )

    try:
        db.add(user)
        await db.commit()
        await db.refresh(user)

    except IntegrityError:
        await db.rollback()
        raise PhoneAlreadyRegistered from None

    return user


# ---------------------------------------------------------------------
# Email verification
# ---------------------------------------------------------------------

async def verify_email_registration(
    db: AsyncSession,
    *,
    email: str,
    code: str,
) -> tuple[User, str, str]:
    normalized_email = email.strip().lower()

    pending = await db.scalar(
        select(PendingVerification)
        .where(PendingVerification.email == normalized_email)
        .order_by(PendingVerification.created_at.desc())
        .with_for_update()
    )

    if pending is None:
        raise InvalidEmailVerificationCode

    now = datetime.now(timezone.utc)
    expiry = pending.expires_at

    if expiry.tzinfo is None:
        expiry = expiry.replace(tzinfo=timezone.utc)

    if expiry <= now:
        await db.delete(pending)
        await db.commit()
        raise InvalidEmailVerificationCode

    if pending.attempts >= settings.email_otp_max_attempts:
        await db.delete(pending)
        await db.commit()
        raise InvalidEmailVerificationCode

    if not verify_email_otp(code, pending.code_hash):
        pending.attempts += 1
        await db.commit()
        raise InvalidEmailVerificationCode

    try:
        if pending.user_id is None:
            # NEW REGISTRATION:
            # The actual account is created only after a correct OTP.
            existing_user = await db.scalar(
                select(User.id).where(User.email == normalized_email)
            )

            if existing_user is not None:
                await db.delete(pending)
                await db.commit()
                raise InvalidEmailVerificationCode

            user = User(
                full_name=pending.full_name,
                email=normalized_email,
                password_hash=pending.password_hash,
                auth_provider="email",
                is_active=True,
                is_verified=True,
                role=pending.role,
                expert_approval_status=(
                    "pending" if pending.role == "expert" else "not_applicable"
),
                preferred_language=pending.preferred_language,
            )

            db.add(user)
            await db.flush()

        else:
            # LEGACY COMPATIBILITY:
            # Older pending records already have an unverified User.
            # Verify that existing account without creating a duplicate.
            user = await db.scalar(
                select(User)
                .where(User.id == pending.user_id)
                .with_for_update()
            )

            if (
                user is None
                or user.email != normalized_email
                or user.is_verified
                or not user.is_active
            ):
                raise InvalidEmailVerificationCode

            user.is_verified = True

        refresh_session, raw_refresh_token = _new_session(user.id)
        db.add(refresh_session)

        await db.delete(pending)
        await db.commit()
        await db.refresh(user)

    except InvalidEmailVerificationCode:
        raise

    except IntegrityError:
        await db.rollback()
        raise InvalidEmailVerificationCode from None

    access_token = create_access_token(str(user.id))

    return user, access_token, raw_refresh_token


# ---------------------------------------------------------------------
# Resend email verification
# ---------------------------------------------------------------------

async def resend_email_verification(
    db: AsyncSession,
    *,
    email: str,
) -> None:
    normalized_email = email.strip().lower()

    pending = await db.scalar(
        select(PendingVerification)
        .where(PendingVerification.email == normalized_email)
        .order_by(PendingVerification.created_at.desc())
        .with_for_update()
    )

    if pending is None:
        raise InvalidEmailVerificationCode

    now = datetime.now(timezone.utc)
    last_sent = pending.created_at

    if last_sent.tzinfo is None:
        last_sent = last_sent.replace(tzinfo=timezone.utc)

    elapsed = (now - last_sent).total_seconds()

    if elapsed < settings.email_otp_resend_cooldown_seconds:
        raise EmailResendTooSoon

    code = generate_email_otp()

    pending.code_hash = hash_email_otp(code)
    pending.expires_at = email_otp_expiration()
    pending.attempts = 0
    pending.created_at = now

    try:
        await send_verification_email(
            recipient_email=normalized_email,
            code=code,
            language=pending.preferred_language,
        )

        await db.commit()

    except Exception as exc:
        await db.rollback()
        raise EmailDeliveryError from exc


# ---------------------------------------------------------------------
# Phone verification
# ---------------------------------------------------------------------

async def verify_phone_registration(
    db: AsyncSession,
    *,
    phone_number: str,
    firebase_id_token: str,
) -> tuple[User, str, str]:
    normalized_phone = phone_number.strip()

    try:
        firebase_uid, verified_phone = verify_phone_identity(
            firebase_id_token
        )
    except FirebaseTokenError:
        raise InvalidPhoneVerification from None

    if verified_phone != normalized_phone:
        raise InvalidPhoneVerification

    user = await db.scalar(
        select(User)
        .where(User.phone_number == normalized_phone)
        .with_for_update()
    )

    if user is None or user.is_verified or not user.is_active:
        raise InvalidPhoneVerification

    existing_identity = await db.scalar(
        select(AuthIdentity).where(
            AuthIdentity.provider == "firebase_phone",
            AuthIdentity.provider_subject == firebase_uid,
        )
    )

    if existing_identity is not None:
        raise InvalidPhoneVerification

    identity = AuthIdentity(
        user_id=user.id,
        provider="firebase_phone",
        provider_subject=firebase_uid,
        provider_email=None,
    )

    user.firebase_uid = firebase_uid
    user.is_verified = True

    db.add(identity)

    refresh_session, raw_refresh_token = _new_session(user.id)
    db.add(refresh_session)

    try:
        await db.commit()
        await db.refresh(user)

    except IntegrityError:
        await db.rollback()
        raise InvalidPhoneVerification from None

    access_token = create_access_token(str(user.id))

    return user, access_token, raw_refresh_token


# ---------------------------------------------------------------------
# Google sign-in
# ---------------------------------------------------------------------

async def authenticate_google_user(
    db: AsyncSession,
    *,
    firebase_id_token: str,
) -> tuple[User, str, str]:
    try:
        google_identity = verify_google_identity(firebase_id_token)
    except FirebaseTokenError:
        raise InvalidGoogleAuthentication() from None

    firebase_uid = google_identity["uid"]
    email = google_identity["email"]
    full_name = google_identity["full_name"]

    existing_identity = await db.scalar(
        select(AuthIdentity).where(
            AuthIdentity.provider == "google",
            AuthIdentity.provider_subject == firebase_uid,
        )
    )

    if existing_identity is not None:
        user = await db.scalar(
            select(User).where(User.id == existing_identity.user_id)
        )

        if user is None or not user.is_active:
            raise InvalidGoogleAuthentication()

    else:
        existing_user = await db.scalar(
            select(User).where(User.email == email)
        )

        if existing_user is not None:
            raise GoogleAccountAlreadyExists()

        user = User(
            full_name=full_name,
            email=email,
            password_hash=None,
            auth_provider="google",
            firebase_uid=firebase_uid,
            is_active=True,
            is_verified=True,
        )

        db.add(user)
        await db.flush()

        db.add(
            AuthIdentity(
                user_id=user.id,
                provider="google",
                provider_subject=firebase_uid,
                provider_email=email,
            )
        )

    refresh_session, raw_refresh_token = _new_session(user.id)
    db.add(refresh_session)

    try:
        await db.commit()
        await db.refresh(user)

    except IntegrityError:
        await db.rollback()
        raise InvalidGoogleAuthentication() from None

    access_token = create_access_token(str(user.id))

    return user, access_token, raw_refresh_token


# ---------------------------------------------------------------------
# Link Google identity to an existing account
# ---------------------------------------------------------------------

async def link_google_identity(
    db: AsyncSession,
    *,
    user: User,
    firebase_id_token: str,
) -> User:
    try:
        google_identity = verify_google_identity(firebase_id_token)
    except FirebaseTokenError:
        raise InvalidGoogleAuthentication() from None

    firebase_uid = google_identity["uid"]
    email = google_identity["email"]

    existing_identity = await db.scalar(
        select(AuthIdentity).where(
            AuthIdentity.provider == "google",
            AuthIdentity.provider_subject == firebase_uid,
        )
    )

    if existing_identity is not None:
        if existing_identity.user_id == user.id:
            raise GoogleIdentityAlreadyLinked()

        raise InvalidGoogleAuthentication()

    existing_email_owner = await db.scalar(
        select(User).where(User.email == email)
    )

    if existing_email_owner is not None and existing_email_owner.id != user.id:
        raise GoogleAccountAlreadyExists()

    identity = AuthIdentity(
        user_id=user.id,
        provider="google",
        provider_subject=firebase_uid,
        provider_email=email,
    )

    db.add(identity)

    try:
        await db.commit()

    except IntegrityError:
        await db.rollback()
        raise InvalidGoogleAuthentication() from None

    return user


# ---------------------------------------------------------------------
# Phone sign-in
# ---------------------------------------------------------------------

async def authenticate_phone_user(
    db: AsyncSession,
    *,
    phone_number: str,
    password: str,
) -> tuple[User, str, str]:
    normalized_phone = phone_number.strip()

    user = await db.scalar(
        select(User).where(User.phone_number == normalized_phone)
    )

    if user is None or user.password_hash is None:
        raise InvalidCredentials()

    if not verify_password(password, user.password_hash):
        raise InvalidCredentials()

    if not user.is_active:
        raise AccountInactive()

    if not user.is_verified:
        raise PhoneVerificationRequired()

    refresh_session, raw_refresh_token = _new_session(user.id)
    db.add(refresh_session)

    await db.commit()

    access_token = create_access_token(str(user.id))

    return user, access_token, raw_refresh_token


# ---------------------------------------------------------------------
# Email sign-in
# ---------------------------------------------------------------------

async def authenticate_user(
    db: AsyncSession,
    *,
    email: str,
    password: str,
) -> tuple[User, str, str]:
    normalized_email = email.strip().lower()

    user = await db.scalar(
        select(User).where(User.email == normalized_email)
    )

    if user is None or user.password_hash is None:
        raise InvalidCredentials()

    if not verify_password(password, user.password_hash):
        raise InvalidCredentials()

    if not user.is_active:
        raise AccountInactive()

    if not user.is_verified:
        raise EmailVerificationRequired()

    refresh_session, raw_refresh_token = _new_session(user.id)
    db.add(refresh_session)

    await db.commit()

    access_token = create_access_token(str(user.id))

    return user, access_token, raw_refresh_token


# ---------------------------------------------------------------------
# Refresh-token rotation
# ---------------------------------------------------------------------

async def rotate_refresh_token(
    db: AsyncSession,
    raw_token: str,
) -> tuple[User, str, str]:
    token_digest = hash_refresh_token(raw_token)

    old_session = await db.scalar(
        select(RefreshSession)
        .where(RefreshSession.token_hash == token_digest)
        .with_for_update()
    )

    if old_session is None:
        raise InvalidRefreshToken

    if old_session.revoked_at is not None:
        await db.execute(
            update(RefreshSession)
            .where(RefreshSession.family_id == old_session.family_id)
            .where(RefreshSession.revoked_at.is_(None))
            .values(revoked_at=datetime.now(timezone.utc))
        )

        await db.commit()
        raise RefreshTokenReuseDetected

    now = datetime.now(timezone.utc)

    if old_session.expires_at <= now:
        raise InvalidRefreshToken

    user = await db.scalar(
        select(User).where(User.id == old_session.user_id)
    )

    if user is None or not user.is_active:
        raise AccountInactive

    if not user.is_verified:
        raise InvalidRefreshToken

    new_session, new_raw_token = _new_session(
        user.id,
        family_id=old_session.family_id,
    )

    db.add(new_session)
    await db.flush()

    old_session.revoked_at = now
    old_session.last_used_at = now
    old_session.replaced_by_id = new_session.id

    await db.commit()

    access_token = create_access_token(str(user.id))

    return user, access_token, new_raw_token


# ---------------------------------------------------------------------
# Logout / revoke refresh token
# ---------------------------------------------------------------------

async def revoke_refresh_token(
    db: AsyncSession,
    raw_token: str,
) -> None:
    token_digest = hash_refresh_token(raw_token)

    session = await db.scalar(
        select(RefreshSession)
        .where(RefreshSession.token_hash == token_digest)
        .with_for_update()
    )

    if session is None or session.revoked_at is not None:
        return

    now = datetime.now(timezone.utc)

    await db.execute(
        update(RefreshSession)
        .where(RefreshSession.family_id == session.family_id)
        .where(RefreshSession.revoked_at.is_(None))
        .values(revoked_at=now)
    )

    await db.commit()
