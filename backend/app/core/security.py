from pwdlib import PasswordHash
import bcrypt

password_hasher = PasswordHash.recommended()


def hash_password(password: str) -> str:
    """Hash new passwords with bcrypt; retain Argon2 for long inputs and old hashes."""
    encoded = password.encode("utf-8")
    if len(encoded) > 72:
        return password_hasher.hash(password)
    return bcrypt.hashpw(encoded, bcrypt.gensalt()).decode("ascii")


def verify_password(password: str, hashed_password: str) -> bool:
    """Verify a password against its stored hash."""
    if hashed_password.startswith(("$2a$", "$2b$", "$2y$")):
        try:
            return bcrypt.checkpw(password.encode("utf-8"), hashed_password.encode("ascii"))
        except (ValueError, TypeError):
            return False
    try:
        return password_hasher.verify(password, hashed_password)
    except Exception:
        return False


def create_access_token(data: dict) -> str:
    """Compatibility helper for imported assistant routes; preserve local JWT claims."""
    from app.core.tokens import create_access_token as create_local_token
    claims = {key: value for key, value in data.items() if key != "sub"}
    return create_local_token(str(data.get("sub", "")), claims)


def decode_token(token: str):
    """Compatibility helper that uses the local issuer, audience and token-type checks."""
    from jwt import InvalidTokenError
    from app.core.tokens import decode_access_token
    try:
        return decode_access_token(token)
    except InvalidTokenError:
        return None
