from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from schemas.vendor import VendorListOut
from sqlalchemy.orm import Session
from typing import List
from db import SessionLocal, get_db
from models.models import User, Vendor
from schemas import VendorCreate, VendorUpdate, VendorOut
from services.auth_service import decode_token
from services.vendor_service import VendorService
from utils.responses import created_response, success_response, error_response
from sqlalchemy.exc import SQLAlchemyError

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login") 

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(token: str = Depends(oauth2_scheme), db=Depends(get_db)):
    """Decode JWT and return current user"""
    payload = decode_token(token)
    uid = payload.get("sub")
    if not uid:
        raise HTTPException(status_code=401, detail="Invalid token")
    user = db.query(User).filter(User.id == int(uid)).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user


@router.post("/", response_model=VendorOut)
def create_vendor(
    payload: VendorCreate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        vendor = VendorService.create_vendor(payload, current_user, db)
        return created_response(
            data=VendorOut.model_validate(vendor),
            message="Vendor created"
        )
    except SQLAlchemyError as e:
        db.rollback()
        return error_response(f"Database error: {str(e)}", 500)
    except Exception as e:
        db.rollback()
        return error_response(f"Unexpected error: {str(e)}", 500)

@router.get("/", response_model=VendorListOut)
def list_vendors(
    wedding_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        result = VendorService.list_vendors(wedding_id, db)
        return success_response(
            data=VendorListOut(
                total_reserved=result["total_reserved"],
                total_pending=result["total_pending"],
                total_rejected=result["total_rejected"],
                total_amount=result["total_amount"],
                paid_amount=result["paid_amount"],
                pending_amount=result["pending_amount"],
                vendors=[VendorOut.model_validate(v) for v in result["vendors"]],
            ),
            message="Vendors fetched"
        )
    except SQLAlchemyError as e:
        return error_response(f"Database error: {str(e)}", 500)
    except Exception as e:
        return error_response(f"Unexpected error: {str(e)}", 500)


@router.put("/{vendor_id}", response_model=VendorOut)
def update_vendor(
    vendor_id: int,
    payload: VendorUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        vendor = VendorService.update_vendor(vendor_id, payload, current_user, db)
        if not vendor:
            return error_response("Vendor not found", 404)

        return success_response(
            data=VendorOut.model_validate(vendor),
            message="Vendor updated"
        )
    except SQLAlchemyError as e:
        return error_response(f"Database error: {str(e)}", 500)
    except Exception as e:
        return error_response(f"Unexpected error: {str(e)}", 500)


@router.delete("/{vendor_id}")
def delete_vendor(
    vendor_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        deleted = VendorService.delete_vendor(vendor_id, current_user, db)
        if not deleted:
            return error_response("Vendor not found", 404)

        return success_response(message="Vendor deleted")
    except SQLAlchemyError as e:
        return error_response(f"Database error: {str(e)}", 500)
    except Exception as e:
        return error_response(f"Unexpected error: {str(e)}", 500)
