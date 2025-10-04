# services/device_service.py
from sqlalchemy.orm import Session
from models.models import Device
from schemas.device import DeviceCreate, DeviceOut
from utils.logger import get_logger

LOGGER = get_logger("device_service")


def upsert_device(db: Session, device_data: DeviceCreate, user_id: int, auth_token: str = None):
    """
    Insert or update device entry for the user.
    """
    device = db.query(Device).filter(Device.device_id == device_data.device_id, Device.user_id == user_id).first()

    if device:
        LOGGER.info(f"Updating device for user {user_id}")
        for field, value in device_data.dict(exclude_unset=True).items():
            setattr(device, field, value)
        if auth_token:
            device.auth_token = auth_token
    else:
        LOGGER.info(f"Registering new device for user {user_id}")
        device = Device(**device_data.dict(), user_id=user_id, auth_token=auth_token)
        db.add(device)

    db.commit()
    db.refresh(device)
    return device


def get_devices_by_user(db: Session, user_id: int):
    return db.query(Device).filter(Device.user_id == user_id).all()


def get_device_by_id(db: Session, device_id: int):
    return db.query(Device).filter(Device.id == device_id).first()


def delete_device(db: Session, device_id: int, user_id: int):
    device = db.query(Device).filter(Device.id == device_id, Device.user_id == user_id).first()
    if device:
        db.delete(device)
        db.commit()
        return True
    return False
