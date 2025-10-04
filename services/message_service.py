from db import SessionLocal
from models.models import Message
from schemas.message import MessageCreate
from utils.responses import success_response

class MessageService:
    @staticmethod
    def send_message(data: MessageCreate, current_user):
        with SessionLocal() as db:
            message = Message(
                content=data.content,
                user_id=current_user.id,
                wedding_id=current_user.wedding_id,
            )
            db.add(message)
            db.commit()
            db.refresh(message)
            return success_response("Message sent", message)

    @staticmethod
    def list_messages(current_user):
        with SessionLocal() as db:
            return db.query(Message).filter(Message.wedding_id == current_user.wedding_id).all()
