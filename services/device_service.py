from sqlalchemy.orm import Session
from models.models import Device
from schemas.device import DeviceCreate
import datetime
from utils.common_service import get_local_time

# Create Device
def upsert_device(db: Session, device_data: DeviceCreate, user_id: int, auth_token: str) -> Device:
    if not device_data or not device_data.device_id:
        return None

    device = db.query(Device).filter(Device.device_id == device_data.device_id).first()

    if device:
        # ✅ Update existing device
        device.device_type = device_data.device_type  # type: ignore
        device.os_version = device_data.os_version  # type: ignore
        device.device_name = device_data.device_name  # type: ignore
        device.app_version = device_data.app_version  # type: ignore
        device.fcm_token = device_data.fcm_token  # type: ignore
        device.latitude = device_data.latitude  # type: ignore
        device.longitude = device_data.longitude  # type: ignore
        device.auth_token = auth_token  # ✅ always set from backend
        device.user_id = user_id  # type: ignore
        device.updated_at = get_local_time()  # ✅ function call
    else:
        # ✅ Create new device
        device = Device(
            device_id=device_data.device_id,
            device_type=device_data.device_type,
            os_version=device_data.os_version,
            device_name=device_data.device_name,
            app_version=device_data.app_version,
            fcm_token=device_data.fcm_token,
            latitude=device_data.latitude,
            longitude=device_data.longitude,
            auth_token=auth_token,  # ✅ backend injected
            user_id=user_id,
        )
        db.add(device)

    db.commit()
    db.refresh(device)
    return device


# Get Device by ID
def get_device(db: Session, device_id: int):
    return db.query(Device).filter(Device.id == device_id).first()


# Get All Devices
def get_devices(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Device).offset(skip).limit(limit).all()


# Update Device
def update_device(db: Session, device_id: int, update_data: dict):
    device = db.query(Device).filter(Device.id == device_id).first()
    if not device:
        return None
    for key, value in update_data.items():
        setattr(device, key, value)
    db.commit()
    db.refresh(device)
    return device


# Delete Device
def delete_device(db: Session, device_id: int):
    device = db.query(Device).filter(Device.id == device_id).first()
    if not device:
        return None
    db.delete(device)
    db.commit()
    return True

