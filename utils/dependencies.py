from fastapi import Depends, HTTPException, status
from jose import jwt, JWTError
from utils.logger import get_logger
from models.models import User
from db import SessionLocal
from typing import Optional
from fastapi.security import OAuth2PasswordBearer
from models.models import User
from db import SessionLocal

SECRET_KEY = "your_jwt_secret_here"
ALGORITHM = "HS256"

LOGGER = get_logger("auth_dependency")


SECRET_KEY = "your_jwt_secret_here"  # Load from env in production
ALGORITHM = "HS256"

def create_access_token(data: dict, embed_user: bool = False) -> str:
    """
    Create a JWT token without expiration.
    - data: dictionary, e.g., {"user_id": user.id, "email": user.email}
    - embed_user: if True, embed extra user info in the token
    """
    to_encode = data.copy()

    if embed_user:
        to_encode.update({
            "email": data.get("email"),
            "user_id": data.get("user_id"),
            "first_name": data.get("first_name"),
            "last_name": data.get("last_name"),
            "role": data.get("role"),
        })

    # No "exp" → token never expires
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def decode_access_token(token: str) -> dict:
    """
    Decode the JWT token.
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except Exception:
        return None



oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        # Ignore expiration if token has none
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM], options={"verify_exp": False})
        user_id: int = payload.get("user_id")
        print(user_id)
        if user_id is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    db = SessionLocal()
    try:
        print(user_id)
        user = db.query(User).filter(User.id == user_id).first()
        if user is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
        return user
    finally:
        db.close()

