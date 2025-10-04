from sqlalchemy.orm import Session
from db import SessionLocal
from models.models import Collaborator, Guest, RoleEnum, Wedding
from schemas.wedding import WeddingBase, WeddingCreate, WeddingOut
from utils.responses import success_response, error_response
import uuid

class WeddingService:
    @staticmethod
    def create_wedding(data: WeddingCreate, current_user, db: Session):
        wedding = Wedding(
            title=data.title,
            name=data.name,
            spouse_name=data.spouse_name,
            wedding_date=data.wedding_date,
            budget_total=data.budget_total,
            guest_code=str(uuid.uuid4())[:8],          # short unique guest code
            collaborator_code=str(uuid.uuid4())[:8],  # short unique collaborator code
            owner_id=current_user.id,
        )
        db.add(wedding)
        db.commit()
        db.refresh(wedding)
        member = Collaborator(
            user_id=current_user.id,
            wedding_id=wedding.id,
            role="creator"
        )
        db.add(member)
        db.commit()

        return wedding


    @staticmethod
    def join_wedding(code: str, current_user, db: Session):
        # First check if it's a guest code
        wedding = db.query(Wedding).filter(Wedding.guest_code == code).first()
        if wedding:
            if wedding.owner_id == current_user.id:
                raise ValueError("Owner cannot join their own wedding as guest")

            # Check if already guest
            existing = db.query(Guest).filter(
                Guest.user_id == current_user.id,
                Guest.wedding_id == wedding.id
            ).first()
            if existing:
                return {"messagge":"You are already a guest in this wedding","role": "guest", "wedding": wedding}

            guest = Guest(
                user_id=current_user.id,
                wedding_id=wedding.id,
                first_name=current_user.first_name or "Guest",  # fallback
                last_name=current_user.last_name or None,
                email=current_user.email,
                phone=None,
                task_ids=""  # ensure not None
            )
            print(RoleEnum.guest.value)
            collaborator = Collaborator(user_id=current_user.id, wedding_id=wedding.id,role=RoleEnum.guest)
            db.add(collaborator)
            db.add(guest)
            db.flush()
            db.refresh(wedding)
            return {"messagge":"You are added a guest in this wedding","role": "guest", "wedding": wedding}

        # Then check collaborator code
        wedding = db.query(Wedding).filter(Wedding.collaborator_code == code).first()
        if wedding:
            if wedding.owner_id == current_user.id:
                raise ValueError("Owner cannot join their own wedding as collaborator")

            # Check if already collaborator
            existing = db.query(Collaborator).filter(
                Collaborator.user_id == current_user.id,
                Collaborator.wedding_id == wedding.id
            ).first()
            if existing:
                return {"messagge":"You are already a collaborator in this wedding","role": "collaborator", "wedding": wedding}

            collaborator = Collaborator(user_id=current_user.id, wedding_id=wedding.id)
            db.add(collaborator)
            db.flush()
            db.refresh(wedding)
            return {"messagge":"You are added a collaborator in this wedding","role": "collaborator", "wedding": wedding}

        # If no match found
        raise ValueError("Invalid wedding code")
    
    @staticmethod
    def get_weddings_for_user(user_id: int, db: Session):
        """Fetch all weddings owned by a user"""
        weddings = db.query(Wedding).filter(Wedding.owner_id == user_id).all()
        return weddings
    
    @staticmethod
    def switch_wedding(wedding_id: int, current_user):
        with SessionLocal() as db:
            wedding = db.query(Wedding).filter(Wedding.id == wedding_id).first()
            if not wedding:
                return error_response("Wedding not found")
            return success_response("Switched wedding", wedding)
    
    @staticmethod
    def list_weddings(current_user, db: Session):
        # Fetch weddings where user is owner or collaborator
        weddings = (
            db.query(Wedding)
            .outerjoin(Collaborator, Wedding.id == Collaborator.wedding_id)
            .filter(
                (Wedding.owner_id == current_user.id) |
                (Collaborator.user_id == current_user.id)
            )
            .distinct()
            .all()
        )

        return [WeddingBase.model_validate(w) for w in weddings]
        