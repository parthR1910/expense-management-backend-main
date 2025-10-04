from pydantic import BaseModel
from typing import Optional, List
import datetime

class TaskCreate(BaseModel):
    wedding_id: int
    name: str
    category: str | None = None
    description: str | None = None
    start_time: datetime.time | None = None
    due_date: datetime.datetime | None = None
    parent_id: int | None = None
    completed: bool

class TaskUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    start_time: Optional[datetime.time]
    due_date: Optional[datetime.datetime] = None
    completed: Optional[bool] = None
    

class TaskOut(BaseModel):
    id: int
    wedding_id: int
    name: str
    category: Optional[str]
    description: Optional[str]
    start_time: Optional[datetime.time]
    due_date: Optional[datetime.datetime]
    completed: bool
    parent_id: Optional[int] = None
    photo: Optional[str] = None
    created_at: Optional[datetime.datetime]

    total_subtasks: int = 0
    subtasks: List["TaskOut"] = []

    model_config = {"from_attributes": True}

TaskOut.update_forward_refs()

class TaskListOut(BaseModel):
    total_tasks: int
    tasks: List[TaskOut]
    


class TaskOutBase(BaseModel):
    id: int
    name: str
    category: Optional[str]
    description: Optional[str]
    start_time: Optional[datetime.time]
    due_date: Optional[datetime.datetime]
    completed: bool
    parent_id: Optional[int] = None

    model_config = {"from_attributes": True}