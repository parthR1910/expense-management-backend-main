from fastapi import APIRouter, Depends
from typing import List
from schemas.message import MessageCreate, MessageOut
from services.message_service import MessageService
from utils.dependencies import get_current_user

router = APIRouter()

@router.post("/", response_model=MessageOut)
def send_message(data: MessageCreate, current_user=Depends(get_current_user)):
    return MessageService.send_message(data, current_user)

@router.get("/", response_model=List[MessageOut])
def list_messages(current_user=Depends(get_current_user)):
    return MessageService.list_messages(current_user)
