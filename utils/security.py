from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
import hashlib

# Create a password hashing context (bcrypt internally)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Secret key for JWT (in production, load from env var)
SECRET_KEY = "your_super_secret_key_here"  # ⚠️ use os.getenv("SECRET_KEY")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours


# ----------------------------------------------------------------------
# Password Hashing (fix for >72 byte passwords)
# ----------------------------------------------------------------------
def _prehash(password: str) -> str:
    return hashlib.sha256(password.encode("utf-8")).hexdigest()

def get_password_hash(password: str) -> str:
    print(f"Original password length: {len(password.encode('utf-8'))} bytes")
    prehashed = _prehash(password)
    print(f"Prehashed length: {len(prehashed.encode('utf-8'))} bytes")
    return pwd_context.hash(prehashed)

def verify_password(plain: str, hashed: str) -> bool:
    try:
        return pwd_context.verify(_prehash(plain), hashed)  # New accounts
    except Exception:
        return pwd_context.verify(plain, hashed)  # Old accounts


