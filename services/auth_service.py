import os
from datetime import datetime, timedelta
from jose import jwt, JWTError
from passlib.context import CryptContext
from typing import Optional
from db import SessionLocal
from models.models import User,Wedding
from sqlalchemy.orm import Session
from schemas.auth import UserUpdate
from utils.logger import get_logger
from utils.exceptions import UnauthorizedException
from google.oauth2 import id_token
from google.auth.transport import requests
from utils.responses import success_response, error_response

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = os.getenv("JWT_SECRET", "change-me")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    encoded = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded

def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError:
        return {}

# basic user helper
def get_user_by_email(db, email: str):
    return db.query(User).filter(User.email == email).first()

def create_user(
    db,
    email: str,
    password: Optional[str] = None,
    google_uid: Optional[str] = None,
    first_name: str = None,
    last_name: str = None,
    login_type: int = None,
):
    user = User(
        email=email,
        first_name=first_name,
        last_name=last_name,
        login_type=login_type,
    )

    if password:  # 🔹 Email/Password flow
        user.hashed_password = get_password_hash(password)

    if google_uid:  # 🔹 Google flow
        user.google_uid = google_uid

    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def set_last_active_wedding(user: User, wedding: Wedding, db: Session) -> User:
    """
    Update user's last active wedding.
        """
    user.last_active_wedding_id = wedding.id
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

GOOGLE_CLIENT_ID = "135664693218-kr81m29srepsea35u2cflt2vbvhld7m6.apps.googleusercontent.com"  # TODO: replace
LOGGER = get_logger("google_auth")
 
def google_authenticate(db: Session, token: str):
    try:
        idinfo = id_token.verify_oauth2_token(token, requests.Request(), GOOGLE_CLIENT_ID)
        if idinfo["iss"] not in ["accounts.google.com", "https://accounts.google.com"]:
            raise UnauthorizedException("Invalid Google issuer")

        email = idinfo["email"]
        first_name = idinfo.get("given_name", "")
        last_name = idinfo.get("family_name", "")

        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(email=email, first_name=first_name, last_name=last_name)
            db.add(user)
            db.commit()
            db.refresh(user)

        access_token = create_access_token({"sub": str(user.id)})
        LOGGER.info(f"Google login success for {email}")

        data = {
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
            },
        }

        return success_response(data=data, message="Google login successful")

    except ValueError as e:
        LOGGER.error(f"Google token validation failed: {e}")
        raise UnauthorizedException("Invalid Google token")
 

def update_user_profile(db: Session, user_id: int, payload: UserUpdate,photo_url: str | None = None):
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return None

        # Update fields from schema
        for field, value in payload.dict(exclude_unset=True).items():
            setattr(user, field, value)

        # Update photo if provided
        if photo_url:
            user.photo = photo_url

        db.commit()
        db.refresh(user)
        return user