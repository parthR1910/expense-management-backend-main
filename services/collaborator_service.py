import enum
from requests import Session
from db import SessionLocal
from models.models import Collaborator, RoleEnum, Wedding
from schemas.collaborator import CollaboratorAdd
from utils.responses import success_response, error_response

class CollaboratorService:
    @staticmethod
    def add_collaborator(data: CollaboratorAdd, current_user):
        with SessionLocal() as db:
            collaborator = Collaborator(**data.dict(), wedding_id=current_user.wedding_id)
            db.add(collaborator)
            db.commit()
            db.refresh(collaborator)
            return success_response("Collaborator added", collaborator)

    @staticmethod
    def list_collaborators(wedding_id: int, db: Session):
        """
        Return all collaborators for a wedding including the owner
        """
        # Get owner
        owner = db.query(Wedding).filter(Wedding.id == wedding_id).first()
        if not owner:
            raise ValueError("Wedding not found")

        owner_data = {
            "id": owner.owner.id,
            "first_name": owner.owner.first_name,
            "last_name": owner.owner.last_name,
            "email": owner.owner.email,
            "role": "owner"
        }

        # Get collaborators
        collaborators = db.query(Collaborator).filter(
            Collaborator.wedding_id == wedding_id,
            Collaborator.role == RoleEnum.collaborator
        ).all()

        collaborator_list = [
            {
                "id": c.user.id,
                "first_name": c.user.first_name,
                "last_name": c.user.last_name,
                "email": c.user.email,
                "role": c.role.value if isinstance(c.role, enum.Enum) else c.role
            }
            for c in collaborators
        ]

        # Combine owner + collaborators
        all_members = [owner_data] + collaborator_list
        return all_members

    @staticmethod
    def remove_collaborator(collab_id: int, current_user):
        with SessionLocal() as db:
            collab = db.query(Collaborator).filter(
                Collaborator.id == collab_id,
                Collaborator.wedding_id == current_user.wedding_id
            ).first()
            if not collab:
                return error_response("Collaborator not found")
            db.delete(collab)
            db.commit()
            return success_response("Collaborator removed", None)
    
    @staticmethod
    def getRole(user, db):
        role_row = db.query(Collaborator.role).filter(
            Collaborator.user_id == user.id
        ).first()

        if role_row:
            # role_row is a Row object → extract real enum
            return role_row.role  # this will be RoleEnum
        return None