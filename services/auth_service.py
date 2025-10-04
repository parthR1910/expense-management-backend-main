from sqlalchemy.orm import Session
from models.models import User
from schemas.auth import RegisterRequest, LoginRequest, AuthResponse
from services import device_service
from schemas.device import DeviceCreate
from utils.security import get_password_hash, verify_password
from utils.dependencies import create_access_token

def register_user(db: Session, payload: RegisterRequest):
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise ValueError("Email already registered")

    hashed_pw = get_password_hash(payload.password)
    user = User(
        email=payload.email,
        hashed_password=hashed_pw,
        first_name=payload.first_name,
        last_name=payload.last_name
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token({
        "user_id": user.id,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "role": user.role.value
    })

    device_data = DeviceCreate(
        device_id=payload.device_id,
        device_type=payload.device_type,
        os_version=payload.os_version,
        device_name=payload.device_name,
        app_version=payload.app_version,
        fcm_token=payload.fcm_token,
        latitude=payload.latitude,
        longitude=payload.longitude,
    )
    device_service.upsert_device(db, device_data, user.id, auth_token=token)

    return AuthResponse(
        access_token=token,
        user_id=user.id,
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        role=user.role.value
    )


def login_user(db: Session, payload: LoginRequest):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise ValueError("Invalid credentials")

    token = create_access_token({
        "user_id": user.id,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "role": user.role.value
    })

    device_data = DeviceCreate(
        device_id=payload.device_id,
        device_type=payload.device_type,
        os_version=payload.os_version,
        device_name=payload.device_name,
        app_version=payload.app_version,
        fcm_token=payload.fcm_token,
        latitude=payload.latitude,
        longitude=payload.longitude,
    )
    device_service.upsert_device(db, device_data, user.id, auth_token=token)

    return AuthResponse(
        access_token=token,
        user_id=user.id,
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        role=user.role.value
    )
