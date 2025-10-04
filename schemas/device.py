# schemas/device.py
from pydantic import BaseModel
from typing import Optional


class DeviceCreate(BaseModel):
    device_id: Optional[str] = None
    device_type: Optional[int] = 0  # 0 = IOS, 1 = Android
    os_version: Optional[str] = None
    device_name: Optional[str] = None
    app_version: Optional[str] = None
    fcm_token: Optional[str] = None
    latitude: Optional[str] = None
    longitude: Optional[str] = None


class DeviceOut(DeviceCreate):
    id: int
    user_id: Optional[int]

    model_config = {"from_attributes": True}
