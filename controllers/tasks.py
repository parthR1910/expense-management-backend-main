from datetime import datetime, time
import os
import uuid
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from fastapi.params import Form
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session
from models.models import Collaborator, Task, User
from schemas import TaskCreate, TaskUpdate, TaskOut
from db import SessionLocal
from schemas.task import TaskListOut, TaskOutBase
from services.task_service import TaskService
from services.auth_service import decode_token,set_last_active_wedding

from utils.responses import created_response, success_response, error_response
from utils.logger import get_logger

router = APIRouter()
LOGGER = get_logger("tasks")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login") 

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(token: str = Depends(oauth2_scheme), db=Depends(get_db)):
    """Decode JWT and return current user"""
    payload = decode_token(token)
    uid = payload.get("sub")
    if not uid:
        raise HTTPException(status_code=401, detail="Invalid token")
    user = db.query(User).filter(User.id == int(uid)).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user



@router.post("/", response_model=TaskOutBase)
async def create_task(
    wedding_id: int = Form(...),
    name: str = Form(...),
    category: str | None = Form(None),
    description: str | None = Form(None),
    start_time: time | None = Form(None),
    due_date: datetime | None = Form(None),
    parent_id: int | None = Form(None),
    completed: bool | None = Form(None),
    photo: UploadFile | None = File(None),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        
        payload = TaskCreate(
            wedding_id=wedding_id,
            name=name,
            category=category,
            description=description,
            start_time=start_time,
            due_date=due_date,
            parent_id=parent_id,
            completed=completed
        )

        
        member = db.query(Collaborator).filter(
            Collaborator.wedding_id == payload.wedding_id,
            Collaborator.user_id == current_user.id
        ).first()
        if not member:
            raise HTTPException(status_code=403, detail="Not a member of this wedding")

       
        photo_url = None
        if photo and photo.filename:
            os.makedirs("media", exist_ok=True)
            ext = photo.filename.split(".")[-1]
            unique_filename = f"{uuid.uuid4().hex}.{ext}"
            file_location = os.path.join("media", unique_filename)

            # Read file content safely
            file_content = await photo.read()
            if file_content:  # only save if file has content
                with open(file_location, "wb") as f:
                    f.write(file_content)
                photo_url = file_location

       
        task = TaskService.create_task(payload, photo_url, db)

        return created_response(
            data=TaskOutBase.model_validate(task),
            message="Task created"
        )

    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

@router.get("/", response_model=TaskListOut)
def list_tasks(
    wedding_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Check collaborator
        member = db.query(Collaborator).filter(
            Collaborator.wedding_id == wedding_id,
            Collaborator.user_id == current_user.id
        ).first()
        if not member:
            return error_response(
                message="Not a member of this wedding", 
                status_code=403
            )

        task_data = TaskService.list_tasks(wedding_id, db)

        return success_response(
            data=task_data,
            message=f"Total tasks: {task_data['total_tasks']}"
        )

    except SQLAlchemyError as e:
        return error_response(
            message=f"Database error: {str(e)}", 
            status_code=500
        )
    except Exception as e:
        return error_response(
            message=f"Unexpected error: {str(e)}", 
            status_code=500
        )



@router.put("/{task_id}", response_model=TaskOutBase)
async def update_task(
    task_id: int,
    name: str | None = Form(None),
    category: str | None = Form(None),
    description: str | None = Form(None),
    start_time: time | None = Form(None),
    due_date: datetime | None = Form(None),
    parent_id: int | None = Form(None),
    completed: bool | None = Form(None),
    photo: UploadFile | None = File(None),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    try:
        
        payload = TaskUpdate(
            name=name,
            category=category,
            description=description,
            start_time=start_time,
            due_date=due_date,
            parent_id=parent_id,
            completed=completed
        )

       
        photo_url = None
        if photo:
            file_location = f"media/{photo.filename}"
            with open(file_location, "wb") as f:
                f.write(await photo.read())
            photo_url = file_location


        task = TaskService.update_task(task_id, payload, db, photo_url)

        if not task:
            return error_response(message="Task not found", status_code=404)

        return success_response(
            data=TaskOutBase.model_validate(task),
            message="Task updated"
        )

    except SQLAlchemyError as e:
        return error_response(message=f"Database error: {str(e)}", status_code=500)
    except Exception as e:
        return error_response(message=f"Unexpected error: {str(e)}", status_code=500)

@router.delete("/{task_id}")
def delete_task(task_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        result = TaskService.delete_task(task_id, db)
        if not result:
            raise HTTPException(status_code=404, detail="Task not found")
        return success_response("Task deleted", None)
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
