from http.client import HTTPException
from fastapi import APIRouter, Depends
from typing import List

from requests import Session
from db import get_db
from schemas.collaborator import CollaboratorAdd, CollaboratorOut
from services.collaborator_service import CollaboratorService
from utils.dependencies import get_current_user

router = APIRouter()

@router.post("/", response_model=CollaboratorOut)
def add_collaborator(data: CollaboratorAdd, current_user=Depends(get_current_user)):
    return CollaboratorService.add_collaborator(data, current_user)

@router.get("/", response_model=dict)
def list_collaborators(wedding_id: int, db: Session = Depends(get_db)):
    """
    List all collaborators for a given wedding including owner
    """
    try:
        members = CollaboratorService.list_collaborators(wedding_id, db)
        return {
            "status": "success",
            "message": "Collaborators fetched successfully",
            "data": members
        }
    except ValueError as e:
        return {
            "status": "error",
            "message": str(e),
            "data": None
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch collaborators: {str(e)}")

@router.delete("/{collab_id}")
def remove_collaborator(collab_id: int, current_user=Depends(get_current_user)):
    return CollaboratorService.remove_collaborator(collab_id, current_user)



