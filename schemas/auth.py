from pydantic import BaseModel
from typing import Optional

class RegisterRequest(BaseModel):
    email: str
    password: str
    first_name: Optional[str]
    last_name: Optional[str]
    device_id: str
    device_type: int
    os_version: Optional[str]
    device_name: Optional[str]
    app_version: Optional[str]
    fcm_token: Optional[str]
    latitude: Optional[str]
    longitude: Optional[str]


class LoginRequest(BaseModel):
    email: str
    password: str
    device_id: str
    device_type: int
    os_version: Optional[str]
    device_name: Optional[str]
    app_version: Optional[str]
    fcm_token: Optional[str]
    latitude: Optional[str]
    longitude: Optional[str]


class AuthResponse(BaseModel):
    access_token: str
    user_id: int
    email: str
    first_name: Optional[str]
    last_name: Optional[str]
    role: Optional[str]
