from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# Request schema to create an approval rule
class ApprovalRuleCreate(BaseModel):
    company_id: int
    rule_type: str  # "percentage" / "special" / "hybrid"
    percentage_required: Optional[int] = None
    special_approver_role: Optional[str] = None

# Request schema to update an approval rule
class ApprovalRuleUpdate(BaseModel):
    rule_type: Optional[str]
    percentage_required: Optional[int]
    special_approver_role: Optional[str]

# Response schema
class ApprovalRuleResponse(BaseModel):
    id: int
    company_id: int
    rule_type: str
    percentage_required: Optional[int]
    special_approver_role: Optional[str]
    created_at: datetime

    class Config:
        orm_mode = True
