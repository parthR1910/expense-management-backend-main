from pydantic import BaseModel
from typing import Optional
import datetime

class CompanyBase(BaseModel):
    name: str
    country: Optional[str] = None
    currency_code: str

class CompanyCreate(CompanyBase):
    pass

class CompanyUpdate(BaseModel):
    name: Optional[str]
    country: Optional[str]
    currency_code: Optional[str]

class CompanyOut(CompanyBase):
    id: int
    created_at: datetime.datetime

    model_config = {"from_attributes": True}
