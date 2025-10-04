from pydantic import BaseModel
from typing import Optional
import datetime

class CollaboratorAdd(BaseModel):
    user_id: int
    role: Optional[str] = "collaborator"

class CollaboratorOut(BaseModel):
    id: int
    user_id: int
    wedding_id: int
    role: str
    joined_at: datetime.datetime

    model_config = {"from_attributes": True}
