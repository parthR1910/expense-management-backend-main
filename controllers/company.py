from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from db import SessionLocal
from schemas.company import CompanyCreate, CompanyUpdate, CompanyOut
from services import company_service
from utils.dependencies import get_current_user
from utils.responses import created_response, error_response

router = APIRouter(prefix="/company", tags=["Company"])

# DB dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# -------------------------------
# Get all companies
# -------------------------------
@router.get("/", response_model=list[CompanyOut])
def list_companies(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    return company_service.get_all_companies(db)


# -------------------------------
# Get single company
# -------------------------------
@router.get("/{company_id}", response_model=CompanyOut)
def get_company(
    company_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    company = company_service.get_company(db, company_id)
    if not company:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Company not found")
    return company


# -------------------------------
# Create company
# -------------------------------
@router.post("/", response_model=CompanyOut)
def create_company(
    payload: CompanyCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    try:
        company = company_service.create_company(db, payload)
        return created_response(
            message="Company created successfully",
            data=company
        )
    except Exception as e:
        return error_response(f"Error while creating company: {str(e)}", 500)


# -------------------------------
# Update company
# -------------------------------
@router.put("/{company_id}", response_model=CompanyOut)
def update_company(
    company_id: int,
    payload: CompanyUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    try:
        company = company_service.update_company(db, company_id, payload)
        if not company:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Company not found")
        return created_response(
            message="Company updated successfully",
            data=company
        )
    except Exception as e:
        return error_response(f"Error while updating company: {str(e)}", 500)


# -------------------------------
# Delete company
# -------------------------------
@router.delete("/{company_id}")
def delete_company(
    company_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    try:
        success = company_service.delete_company(db, company_id)
        if not success:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Company not found")
        return created_response(message="Company deleted successfully")
    except Exception as e:
        return error_response(f"Error while deleting company: {str(e)}", 500)
