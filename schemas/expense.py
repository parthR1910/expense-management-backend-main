from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum


class ExpenseStatus(str, Enum):
    pending = "Pending"
    approved = "Approved"
    rejected = "Rejected"


# Request schema to create or update expense
class ExpenseCreate(BaseModel):
    company_id: int
    employee_id: int
    amount_original: float
    currency_original: str
    amount_in_company_currency: float
    category: str
    description: Optional[str] = None
    date: Optional[datetime] = None
    receipt_url: Optional[str] = None


class ExpenseUpdate(BaseModel):
    amount_original: Optional[float]
    currency_original: Optional[str]
    amount_in_company_currency: Optional[float]
    category: Optional[str]
    description: Optional[str]
    status: Optional[ExpenseStatus]
    receipt_url: Optional[str]


# Response schema
class ExpenseResponse(BaseModel):
    id: int
    company_id: int
    employee_id: int
    amount_original: float
    currency_original: str
    amount_in_company_currency: float
    category: str
    description: Optional[str]
    date: datetime
    receipt_url: Optional[str]
    status: ExpenseStatus
    current_step: int
    created_at: datetime

    class Config:
        orm_mode = True
