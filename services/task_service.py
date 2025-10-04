from datetime import datetime
from sqlalchemy import case, asc
from sqlalchemy.orm import Session
import db
from models.models import Task
from schemas import TaskCreate, TaskUpdate
from utils.common_service import get_local_time
from utils.responses import success_response, error_response

class TaskService:
    @staticmethod
    def create_task(data: TaskCreate,photo_url: str, db: Session):
        task = Task(
            wedding_id=data.wedding_id,
            parent_id=data.parent_id,
            name=data.name,
            category=data.category,
            description=data.description,
            start_time=data.start_time,
            due_date=data.due_date,
            completed=data.completed if hasattr(data, "completed") else False,
            photo=photo_url,
            created_at=get_local_time()
        )
        db.add(task)
        db.commit()
        db.refresh(task)
        return task

    @staticmethod
    def list_tasks(wedding_id: int, db: Session):
        today = datetime.now()

        tasks = (
            db.query(Task)
            .filter(Task.wedding_id == wedding_id)
            .order_by(
                case(
                    (Task.due_date < today, 1),  # Past tasks go later
                    else_=0                      # Upcoming tasks go first
                ),
                asc(Task.due_date)  # Then sort by earliest due date
            )
            .all()
        )

        task_map = {task.id: task for task in tasks}

       
        for task in tasks:
            if task.parent_id and task.parent_id in task_map:
                parent = task_map[task.parent_id]
                if not hasattr(parent, "subtasks_list"):
                    parent.subtasks_list = []
                parent.subtasks_list.append(task)

        
        root_tasks = [t for t in tasks if t.parent_id is None]
        subtasks = [t for t in tasks if t.parent_id is not None]

        
        def serialize_task(task: Task):
            return {
                "id": task.id,
                "wedding_id": task.wedding_id,
                "name": task.name,
                "category": task.category,
                "description": task.description,
                "start_time": task.start_time,
                "due_date": task.due_date,
                "completed": task.completed,
                "parent_id": task.parent_id,
                "photo": task.photo,
                "created_at": task.created_at,
                "total_subtasks": len(getattr(task, "subtasks_list", [])),
                "subtasks": [serialize_task(st) for st in getattr(task, "subtasks_list", [])],
            }

      
        total_tasks = len(root_tasks)
        total_subtasks = len(subtasks)

        completed_tasks = len([t for t in root_tasks if t.completed])
        pending_tasks = len([t for t in root_tasks if not t.completed])

        completed_subtasks = len([t for t in subtasks if t.completed])
        pending_subtasks = len([t for t in subtasks if not t.completed])

        return {
            "total_tasks": total_tasks,
            "total_subtasks": total_subtasks,
            "completed_tasks": completed_tasks,
            "pending_tasks": pending_tasks,
            "completed_subtasks": completed_subtasks,
            "pending_subtasks": pending_subtasks,
            "tasks": [serialize_task(t) for t in root_tasks],
        }

    @staticmethod
    def update_task(task_id: int, data: TaskUpdate, db: Session, photo_url: str | None = None):
        task = db.query(Task).filter(
            Task.id == task_id,
        ).first()

        if not task:
            return None

        # Update fields from TaskUpdate
        for field, value in data.dict(exclude_unset=True).items():
            setattr(task, field, value)

        # Update photo if provided
        if photo_url:
            task.photo = photo_url

        db.commit()
        db.refresh(task)
        return task

    @staticmethod
    def delete_task(task_id: int, db: Session):
        task = db.query(Task).filter(Task.id == task_id).first()
        if not task:
            return None
        db.delete(task)   # subtasks auto-deleted
        db.commit()
        return True
