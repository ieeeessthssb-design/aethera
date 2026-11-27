from functools import lru_cache
from pathlib import Path

import firebase_admin
from firebase_admin import credentials

from app.core.config import settings


class FirebaseConfigurationError(RuntimeError):
    """The backend has no usable Firebase Admin credentials configured."""


@lru_cache(maxsize=1)
def get_firebase_app() -> firebase_admin.App:
    if not settings.firebase_project_id:
        raise FirebaseConfigurationError("Firebase project ID is not configured.")

    if not settings.firebase_credentials_path:
        raise FirebaseConfigurationError("Firebase Admin credentials path is not configured.")

    credentials_path = Path(settings.firebase_credentials_path)

    if not credentials_path.is_file():
        raise FirebaseConfigurationError("Firebase Admin credentials file was not found.")

    credential = credentials.Certificate(str(credentials_path))

    return firebase_admin.initialize_app(
        credential,
        options={"projectId": settings.firebase_project_id},
        name="aethera",
    )
