from db import SessionLocal
from models.models import Schedule
from schemas.schedule import ScheduleCreate, ScheduleUpdate
from utils.responses import success_response, error_response

class ScheduleService:
    @staticmethod
    def create_schedule(data: ScheduleCreate, current_user):
        with SessionLocal() as db:
            schedule = Schedule(**data.dict(), user_id=current_user.id)
            db.add(schedule)
            db.commit()
            db.refresh(schedule)
            return success_response("Schedule created", schedule)

    @staticmethod
    def list_schedules(current_user):
        with SessionLocal() as db:
            return db.query(Schedule).filter(Schedule.user_id == current_user.id).all()

    @staticmethod
    def update_schedule(schedule_id: int, data: ScheduleUpdate, current_user):
        with SessionLocal() as db:
            schedule = db.query(Schedule).filter(Schedule.id == schedule_id, Schedule.user_id == current_user.id).first()
            if not schedule:
                return error_response("Schedule not found")
            for field, value in data.dict(exclude_unset=True).items():
                setattr(schedule, field, value)
            db.commit()
            db.refresh(schedule)
            return success_response("Schedule updated", schedule)

    @staticmethod
    def delete_schedule(schedule_id: int, current_user):
        with SessionLocal() as db:
            schedule = db.query(Schedule).filter(Schedule.id == schedule_id, Schedule.user_id == current_user.id).first()
            if not schedule:
                return error_response("Schedule not found")
            db.delete(schedule)
            db.commit()
            return success_response("Schedule deleted", None)
