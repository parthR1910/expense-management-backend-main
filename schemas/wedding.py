from pydantic import BaseModel
from typing import Optional, List
import datetime
from schemas.auth import UserOut
from schemas.task import TaskOut, TaskOutBase
from schemas.budget import CostOut
from schemas.vendor import VendorOut
from schemas.schedule import ScheduleOut
from schemas.guest import GuestOut

class WeddingCreate(BaseModel):
    title: Optional[str] = None
    name: Optional[str] = None
    spouse_name: Optional[str] = None
    wedding_date: Optional[datetime.datetime] = None
    budget_total: Optional[float] = 0.0

class WeddingOut(BaseModel):
    id: int
    title: Optional[str]
    name: Optional[str]
    spouse_name: Optional[str]
    wedding_date: Optional[datetime.datetime]
    budget_total: float
    guest_code: str
    collaborator_code: str
    created_at: datetime.datetime

    # 🔹 Nested objects
    owner: UserOut
    tasks: List[TaskOutBase] = []
    budgets: List[CostOut] = []
    vendors: List[VendorOut] = []
    schedules: List[ScheduleOut] = []
    guests: List[GuestOut] = []

    model_config = {"from_attributes": True}
    
    



class WeddingOutBase(BaseModel):
    id: int
    title: Optional[str]
    name: Optional[str]
    spouse_name: Optional[str]
    wedding_date: Optional[datetime.datetime]
    budget_total: float
    guest_code: str
    collaborator_code: str
    created_at: datetime.datetime

    # 🔹 Nested objects
    owner: UserOut

    model_config = {"from_attributes": True}
    

class WeddingBase(BaseModel):
    id: int
    title: Optional[str]
    name: Optional[str]
    spouse_name: Optional[str]
    wedding_date: Optional[datetime.datetime]
    budget_total: float
    guest_code: str
    collaborator_code: str
    created_at: datetime.datetime

    # 🔹 Nested objects
    owner: UserOut

    model_config = {"from_attributes": True}


class WeddingListResponse(BaseModel):
    status: str
    message: str
    data: List[WeddingBase]
