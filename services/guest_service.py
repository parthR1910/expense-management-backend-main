from typing import List
from fastapi import HTTPException
from requests import Session
from db import SessionLocal
from models.models import Collaborator, Guest, RoleEnum
from schemas.guest import GuestCreate, GuestOut, GuestUpdate
from utils.responses import success_response, error_response

class GuestService:
    @staticmethod
    def add_guest(data: GuestCreate, current_user, db: Session):
        try:
            # Convert task_ids list to string
            guest = Guest(
                wedding_id=data.wedding_id,
                first_name=data.first_name,
                last_name=data.last_name,
                gender=data.gender,
                age_criteria=data.age_criteria,
                phone=data.phone,
                email=data.email,
                address=data.address,
                note=data.note,
                group_category=data.group_category,
                user_id=current_user.id,
            )

            if data.task_ids:
                guest.set_task_ids(data.task_ids)

            db.add(guest)
            db.flush()

            # Ensure collaborator is linked
            existing_member = db.query(Collaborator).filter(
                Collaborator.user_id == current_user.id,
                Collaborator.wedding_id == guest.wedding_id
            ).first()

            if not existing_member:
                collaborator = Collaborator(
                    user_id=current_user.id,
                    wedding_id=guest.wedding_id,
                    role=RoleEnum.guest
                )
                db.add(collaborator)

            db.commit()
            db.refresh(guest)

            return guest
        except Exception as e:
            db.rollback()
            raise
    @staticmethod
    def list_guests(wedding_id: int, db: Session):
        guests = db.query(Guest).filter(Guest.wedding_id == wedding_id).all()
        return guests

    @staticmethod
    def update_guest(guest_id: int, data: GuestUpdate, current_user, db: Session):
        guest = db.query(Guest).filter(
            Guest.id == guest_id,
            Guest.user_id == current_user.id
        ).first()

        if not guest:
            raise HTTPException(status_code=404, detail="Guest not found")

        # Update only fields provided
        for field, value in data.dict(exclude_unset=True).items():
            # Special handling for task_ids (expect list from API)
            if field == "task_ids" and value is not None:
                guest.set_task_ids(value)   # convert list -> string
            else:
                setattr(guest, field, value)

        db.commit()
        db.refresh(guest)

        # Return GuestOut schema with task_ids as list
        return GuestOut.model_validate({
            **guest.__dict__,
            "task_ids": guest.get_task_ids()
        })
    @staticmethod
    def delete_guest(guest_id: int, current_user, db: Session):
        guest = db.query(Guest).filter(
            Guest.id == guest_id,
            Guest.user_id == current_user.id
        ).first()

        if not guest:
            raise HTTPException(status_code=404, detail="Guest not found")

        # Delete related collaborator (role = guest)
        collaborator = db.query(Collaborator).filter(
            Collaborator.user_id == current_user.id,
            Collaborator.wedding_id == guest.wedding_id,
            Collaborator.role == RoleEnum.guest
        ).first()

        if collaborator:
            db.delete(collaborator)

        db.delete(guest)
        db.commit()

        return guest
