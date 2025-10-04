import os
import uuid
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from typing import List, Optional

from fastapi.params import Form
from requests import Session
from db import get_db
from models.models import Collaborator, User
from schemas.budget import CostCreate, CostPaymentOut, CostUpdate, CostOut
from services.PaymentService import PaymentService
from services.budget_service import BudgetService
from utils.dependencies import get_current_user
from utils.responses import created_response, success_response, error_response
from settings import MEDIA_DIR
router = APIRouter()

@router.post("/", response_model=CostOut)
async def create_budget(
    wedding_id: int = Form(...),
    name: str = Form(...),
    category: str = Form(...),
    estimate_amount: float = Form(...),
    note: Optional[str] = Form(None),
    photo: UploadFile | None = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        payload = CostCreate(
            wedding_id=wedding_id,
            name=name,
            category=category,
            estimate_amount=estimate_amount,
            note=note,
        )
        member = db.query(Collaborator).filter(
            Collaborator.wedding_id == payload.wedding_id,
            Collaborator.user_id == current_user.id
        ).first()
        if not member:
            raise HTTPException(status_code=403, detail="Not a member of this wedding")

        photo_path = None
        if photo and photo.filename:
            os.makedirs(MEDIA_DIR, exist_ok=True)
            ext = photo.filename.split(".")[-1]
            unique_filename = f"{uuid.uuid4().hex}.{ext}"
            file_location = os.path.join(MEDIA_DIR, unique_filename)

            file_content = await photo.read()
            if file_content:  # only save if file has content
                with open(file_location, "wb") as f:
                    f.write(file_content)
                photo_path = file_location

        budget = BudgetService.create_budget(payload, current_user, db, photo_path)
        db.commit()

        return created_response(
            data=CostOut.model_validate(budget),
            message="Budget created"
        )

    except ValueError as e:
        db.rollback()
        return error_response(str(e))
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
  


@router.get("/", response_model=dict)
def list_budgets(
    wedding_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        member = db.query(Collaborator).filter(
            Collaborator.wedding_id == wedding_id,
            Collaborator.user_id == current_user.id
        ).first()
        if not member:
            raise HTTPException(status_code=403, detail="Not a member of this wedding")
        
        result = BudgetService.list_budgets(wedding_id, db)
        return success_response(data=result, message="Budgets fetched")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@router.put("/{budget_id}", response_model=CostOut)
async def update_budget(
    budget_id: int,
    name: str = Form(...),
    category: str = Form(...),
    estimate_amount: float = Form(...),
    note: Optional[str] = Form(None),
    photo: UploadFile | None = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        payload = CostUpdate(
            name=name,
            category=category,
            estimate_amount=estimate_amount,
            note=note,
        )
        

        photo_path = None
        if photo and photo.filename:
            os.makedirs(MEDIA_DIR, exist_ok=True)
            ext = photo.filename.split(".")[-1]
            unique_filename = f"{uuid.uuid4().hex}.{ext}"
            file_location = os.path.join(MEDIA_DIR, unique_filename)

            file_content = await photo.read()
            if file_content:  # only save if file has content
                with open(file_location, "wb") as f:
                    f.write(file_content)
                photo_path = file_location

        budget = BudgetService.update_budget(budget_id, payload, current_user, db, photo_path)
        db.commit()

        return success_response(
            data=CostOut.model_validate(budget),
            message="Budget updated"
        )

    except ValueError as e:
        db.rollback()
        return error_response(str(e))
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")


@router.delete("/{budget_id}")
def delete_budget(
    budget_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        BudgetService.delete_budget(budget_id, current_user, db)
        db.commit()
        return success_response(message="Budget deleted")
    except ValueError as e:
        db.rollback()
        return error_response(str(e))
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/create-payment", response_model=CostPaymentOut)
async def create_payment(
    name: str = Form(None),
    cost_id: int = Form(...),
    vendor_id: int | None = Form(None),
    amount: float = Form(...),
    paymentdate: str = Form(...),
    note: str | None = Form(None),
    isPaid: bool = Form(None),
    photo: UploadFile | None = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        
        photo_url = None
        if photo and photo.filename:
            os.makedirs("media", exist_ok=True)
            ext = photo.filename.split(".")[-1]
            unique_filename = f"{uuid.uuid4().hex}.{ext}"
            file_location = os.path.join("media", unique_filename)

            # Read file content safely
            file_content = await photo.read()
            if file_content:  # only save if file has content
                with open(file_location, "wb") as f:
                    f.write(file_content)
                photo_url = file_location
        payment = PaymentService.create_payment(name,isPaid,photo_url,cost_id,paymentdate, vendor_id, current_user.id, amount, db, note)
        db.commit()
        return created_response(data=CostPaymentOut.model_validate(payment), message="Payment added")
    except ValueError as e:
        print(e.args)
        db.rollback()
        print
        return error_response(str(e))
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")


@router.get("/payments/{cost_id}")
def list_payments(cost_id: int, db: Session = Depends(get_db)):
    payments = PaymentService.list_payments_for_cost(cost_id, db)
    total_paid = PaymentService.get_total_paid(cost_id, db)
    return success_response(
        data={"payments": payments, "total_paid": total_paid},
        message="Payments fetched"
    )


@router.put("/update-payment/{payment_id}")
async def update_payment(
    payment_id: int,
    name: str = Form(None),
    amount: float = Form(None),
    isPaid: bool = Form(None),
    note: str | None = Form(None),
    photo: UploadFile | None = File(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        photo_url = None
        if photo and photo.filename:
            os.makedirs("media", exist_ok=True)
            ext = photo.filename.split(".")[-1]
            unique_filename = f"{uuid.uuid4().hex}.{ext}"
            file_location = os.path.join("media", unique_filename)

            file_content = await photo.read()
            if file_content:
                with open(file_location, "wb") as f:
                    f.write(file_content)
                photo_url = file_location

        payment = PaymentService.update_payment(
            payment_id=payment_id,
            db=db,
            user_id=current_user.id,
            name=name,
            amount=amount,
            isPaid=isPaid,
            note=note,
            photo_url=photo_url
        )
        db.commit()
        return success_response(data=payment, message="Payment updated successfully")
    
    except ValueError as e:
        db.rollback()
        return error_response(str(e))
    
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
    
    

@router.delete("/payments/{payment_id}")
def delete_payment(
    payment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):  
    try:
        success = PaymentService.delete_payment(payment_id, db, current_user)
        db.commit()
        return success_response(message="Payment deleted successfully")
    except ValueError as e:
        db.rollback()
        return error_response(str(e))
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")