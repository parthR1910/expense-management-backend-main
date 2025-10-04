from fastapi import APIRouter, Depends, HTTPException
from typing import List

from requests import Session
from db import get_db
from schemas.guest import GuestCreate, GuestUpdate, GuestOut
from services.guest_service import GuestService
from utils.dependencies import get_current_user
from utils.responses import error_response, success_response,created_response

router = APIRouter()

@router.post("/", response_model=GuestOut)
def add_guest(
    data: GuestCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    try:
        print(data)
        guest = GuestService.add_guest(data, current_user, db)

        # Convert task_ids string -> list for response
        guest_out = GuestOut.model_validate({
            **guest.__dict__,
            "task_ids": guest.get_task_ids()
        })

        return created_response(
            message="Guest added successfully",
            data=guest_out
        )
    except Exception as e:
        return error_response(f"Error while adding guest: {str(e)}", 500)

@router.get("/", response_model=dict)
def list_guests(
    wedding_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """
    List all guests for a wedding with custom response and exception handling
    """
    try:
        guests = GuestService.list_guests(wedding_id, db)

        # Convert each Guest to GuestOut, mapping task_ids string -> list
        guest_list = []
        for g in guests:
            guest_out = GuestOut.model_validate({
                **g.__dict__,
                "task_ids": g.get_task_ids()
            })
            guest_list.append(guest_out)

        return {
            "status": "success",
            "message": "Guests fetched successfully",
            "data": guest_list
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch guests: {str(e)}"
        )

@router.put("/{guest_id}", response_model=dict)
def update_guest(
    guest_id: int,
    data: GuestUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    """
    Update a guest with custom response & task_ids handling
    """
    try:
        guest_out = GuestService.update_guest(guest_id, data, current_user, db)

        return {
            "status": "success",
            "message": "Guest updated successfully",
            "data": guest_out
        }
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update guest: {str(e)}")

@router.delete("/{guest_id}", response_model=dict)
def delete_guest(
    guest_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    try:
        result = GuestService.delete_guest(guest_id, current_user, db)
        if result:
            return success_response("Guest deleted", None)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete guest: {str(e)}")
