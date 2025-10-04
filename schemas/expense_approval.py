from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum
from schemas.expense import ExpenseStatus

# Request schema for creating an approval
class ExpenseApprovalCreate(BaseModel):
    expense_id: int
    approver_id: int
    step_number: int
    status: Optional[ExpenseStatus] = ExpenseStatus.pending
    comments: Optional[str] = None

# Request schema for updating approval
class ExpenseApprovalUpdate(BaseModel):
    status: Optional[ExpenseStatus]
    comments: Optional[str] = None
    approved_at: Optional[datetime] = None

# Response schema
class ExpenseApprovalResponse(BaseModel):
    id: int
    expense_id: int
    approver_id: int
    step_number: int
    status: ExpenseStatus
    comments: Optional[str]
    approved_at: Optional[datetime]

    class Config:
        orm_mode = True
