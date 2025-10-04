from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# Request schema to create a workflow step
class ApprovalWorkflowCreate(BaseModel):
    company_id: int
    step_number: int
    role_required: str
    sequence_order: int

# Request schema to update a workflow step
class ApprovalWorkflowUpdate(BaseModel):
    step_number: Optional[int]
    role_required: Optional[str]
    sequence_order: Optional[int]

# Response schema
class ApprovalWorkflowResponse(BaseModel):
    id: int
    company_id: int
    step_number: int
    role_required: str
    sequence_order: int
    created_at: datetime

    class Config:
        orm_mode = True
