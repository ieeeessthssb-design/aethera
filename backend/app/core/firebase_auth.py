
import logging
from typing import Any

from firebase_admin import auth

from app.core.firebase import get_firebase_app

logger = logging.getLogger(__name__)

class FirebaseTokenError(Exception):
    pass

def verify_firebase_id_token(id_token: str) -> dict[str, Any]:
    """Verify a Firebase ID token using Firebase Admin SDK."""
    if not id_token or not id_token.strip():
        raise FirebaseTokenError("Firebase ID token is missing.")

    try:
        firebase_app = get_firebase_app()

        decoded_token = auth.verify_id_token(
            id_token.strip(),
            app=firebase_app,
            check_revoked=True,
        )

        return decoded_token

    except Exception as exc:
        # Log the underlying error for debugging.
        # Never log the actual authentication token.
        logger.exception(
            "Firebase ID token verification failed: %s",
            type(exc).__name__,
        )

        raise FirebaseTokenError(
            "Firebase identity verification failed."
        ) from exc

def verify_phone_identity(id_token: str) -> tuple[str, str]:
    """Verify a Firebase phone-authentication identity."""
    decoded_token = verify_firebase_id_token(id_token)

    if not decoded_token.get("phone_number_verified", False):
        raise FirebaseTokenError("Phone number is not verified.")

    firebase_uid = decoded_token.get("uid")
    phone_number = decoded_token.get("phone_number")
    firebase_claims = decoded_token.get("firebase", {})

    if not firebase_uid or not phone_number:
        raise FirebaseTokenError("Phone identity is incomplete.")

    if firebase_claims.get("sign_in_provider") != "phone":
        raise FirebaseTokenError(
            "Token was not issued by phone authentication."
        )

    return firebase_uid, phone_number

def verify_google_identity(id_token: str) -> dict[str, str]:
    """Verify a Firebase Google-authentication identity."""
    decoded_token = verify_firebase_id_token(id_token)

    firebase_uid = decoded_token.get("uid")
    email = decoded_token.get("email")
    firebase_claims = decoded_token.get("firebase", {})

    if not firebase_uid or not email:
        raise FirebaseTokenError("Google identity is incomplete.")

    if not decoded_token.get("email_verified", False):
        raise FirebaseTokenError("Google email is not verified.")

    if firebase_claims.get("sign_in_provider") != "google.com":
        raise FirebaseTokenError(
            "Token was not issued by Google authentication."
        )

    return {
        "uid": str(firebase_uid),
        "email": str(email).strip().lower(),
        "full_name": str(
            decoded_token.get("name") or "AETHERA Farmer"
        ),
    }