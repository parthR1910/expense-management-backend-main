from pydantic import BaseModel
from typing import Optional
import datetime

class MessageCreate(BaseModel):
    content: str

class MessageOut(BaseModel):
    id: int
    user_id: int
    wedding_id: int
    content: str
    created_at: datetime.datetime

    model_config = {"from_attributes": True}
