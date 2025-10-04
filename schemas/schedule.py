from pydantic import BaseModel
from typing import Optional
import datetime

class ScheduleCreate(BaseModel):
    title: str
    category: Optional[str] = None
    date: datetime.date
    time: Optional[str] = None

class ScheduleUpdate(BaseModel):
    title: Optional[str] = None
    category: Optional[str] = None
    date: Optional[datetime.date] = None
    time: Optional[str] = None

class ScheduleOut(BaseModel):
    id: int
    title: str
    category: Optional[str]
    date: datetime.date
    time: Optional[str]
    created_at: datetime.datetime

    model_config = {"from_attributes": True}
