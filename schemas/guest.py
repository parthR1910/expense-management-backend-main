from typing import List
from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
import datetime

from schemas.task import TaskOut

class GuestCreate(BaseModel):
    wedding_id: int
    task_ids: Optional[List[int]] = None
    first_name: str
    last_name: Optional[str] = None
    gender: Optional[str] = None                 # Male/Female/Other
    age_criteria: Optional[str] = None           # Adult/Child
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    address: Optional[str] = None
    note: Optional[str] = None
    group_category: Optional[str] = None

    

class GuestOut(BaseModel):
    id: int
    wedding_id: int
    task_ids: List[int] = []
    first_name: str
    last_name: Optional[str] = None
    gender: Optional[str] = None
    age_criteria: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    address: Optional[str] = None
    note: Optional[str] = None
    group_category: Optional[str] = None
    created_at: datetime.datetime

    model_config = {"from_attributes": True}

    @field_validator("task_ids", mode="before")
    def parse_task_ids(cls, v):
        """
        Convert comma-separated string from DB to List[int].
        Handles empty string and None.
        """
        if isinstance(v, str):
            return [int(i) for i in v.split(",") if i.strip()]
        if v is None:
            return []
        return v
class GuestUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    gender: Optional[str] = None  # Male / Female / Other
    age_criteria: Optional[str] = None  # Adult / Child
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    note: Optional[str] = None
    group_category: Optional[str] = None
    task_ids: Optional[List[int]] = None   # linked task (instead of event_category)
    name: Optional[str] = None      # fallback name (if no split first/last)
    created_at: Optional[datetime.datetime] = None

    model_config = {
        "from_attributes": True
    }



