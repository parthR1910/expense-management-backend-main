from pydantic import BaseModel, EmailStr
from typing import List, Optional
import datetime

from schemas.budget import CostPaymentOut

class VendorCreate(BaseModel):
    name: str
    category: str
    wedding_id: int
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    site: Optional[str] = None
    address: Optional[str] = None
    amount: Optional[float] = 0.0
    status: Optional[str] = "Pending"
    note: Optional[str] = None
    add_budget: Optional[bool] = False

class VendorUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    site: Optional[str] = None
    address: Optional[str] = None
    amount: Optional[float] = None
    status: Optional[str] = None
    note: Optional[str] = None

class VendorOut(BaseModel):
    id: int
    name: str
    category: str
    phone: Optional[str]
    email: Optional[str]
    site: Optional[str]
    address: Optional[str]
    amount: float
    status: str
    note: Optional[str]
    created_at: datetime.datetime

    # 🔹 New fields
    cost_id: Optional[int] = None
    total_amount: float = 0.0
    paid_amount: float = 0.0
    pending_amount: float = 0.0
    balance_amount: float = 0.0
    payments: List[CostPaymentOut] = [] 

    model_config = {"from_attributes": True}


class VendorListOut(BaseModel):
    total_reserved: int
    total_pending: int
    total_rejected: int
    total_amount: float
    paid_amount: float
    pending_amount: float
    vendors: List[VendorOut]

    model_config = {"from_attributes": True}
