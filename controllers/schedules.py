from fastapi import APIRouter, Depends
from typing import List
from schemas.schedule import ScheduleCreate, ScheduleUpdate, ScheduleOut
from services.schedule_service import ScheduleService
from utils.dependencies import get_current_user

router = APIRouter()

@router.post("/", response_model=ScheduleOut)
def create_schedule(data: ScheduleCreate, current_user=Depends(get_current_user)):
    return ScheduleService.create_schedule(data, current_user)

@router.get("/", response_model=List[ScheduleOut])
def list_schedules(current_user=Depends(get_current_user)):
    return ScheduleService.list_schedules(current_user)

@router.put("/{schedule_id}", response_model=ScheduleOut)
def update_schedule(schedule_id: int, data: ScheduleUpdate, current_user=Depends(get_current_user)):
    return ScheduleService.update_schedule(schedule_id, data, current_user)

@router.delete("/{schedule_id}")
def delete_schedule(schedule_id: int, current_user=Depends(get_current_user)):
    return ScheduleService.delete_schedule(schedule_id, current_user)
