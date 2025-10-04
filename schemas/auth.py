from pydantic import BaseModel, EmailStr
from typing import Optional
from schemas.device import DeviceCreate

class UserCreate(BaseModel):
    email: EmailStr
    password: Optional[str] = None
    google_uid: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    login_type: Optional[int] = 0
    device: Optional[DeviceCreate] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: Optional[str] = None
    google_uid: Optional[str] = None
    device: Optional[DeviceCreate] = None

class UserOut(BaseModel):
    id: int
    email: EmailStr
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    photo: Optional[str] = None
    login_type: Optional[int] = None

    model_config = {"from_attributes": True}

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserOutWithBearer(BaseModel):
    id: int
    email: EmailStr
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    login_type: Optional[int] = None
    bearer: Optional[Token]=None
    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    first_name: Optional[str]
    last_name: Optional[str]
    