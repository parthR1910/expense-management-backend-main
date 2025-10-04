from pydantic import BaseModel
from typing import List, Optional
import datetime

class CostCreate(BaseModel):
    wedding_id: int
    name: str
    category: str
    estimate_amount: float
    note: Optional[str] = None

class CostUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    estimate_amount: Optional[float] = None
    note: Optional[str] = None

class CostPaymentOut(BaseModel):
    id: int
    name:str
    photo: Optional[str]
    amount: float
    note: Optional[str]
    isPaid: bool
    paymentdate:datetime.datetime
    created_at: datetime.datetime

    model_config = {"from_attributes": True}


class CostOut(BaseModel):
    id: int
    name: str
    category: Optional[str]
    estimate_amount: float
    note: Optional[str]
    photo: Optional[str]
    created_at: datetime.datetime
    vendor_id: Optional[int]
    paid_amount: float
    pending_amount: float
    balance_amount: float
    is_paid: bool
    payment_count: int

    payments: List[CostPaymentOut] = []

    model_config = {"from_attributes": True}
    
    
