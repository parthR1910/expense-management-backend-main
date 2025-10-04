from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from db import get_db
from models.models import User
from services.auth_service import SECRET_KEY, ALGORITHM
from utils.exceptions import UnauthorizedException

# OAuth2 scheme expects the Authorization: Bearer <token> header
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise UnauthorizedException("Invalid authentication token")

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise UnauthorizedException("User not found")

        return user
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
