from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from db import SessionLocal
from schemas.expense_approval import ExpenseApprovalCreate, ExpenseApprovalUpdate, ExpenseApprovalResponse
from services import expense_approval_service

router = APIRouter(prefix="/expense-approvals", tags=["Expense Approvals"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/", response_model=ExpenseApprovalResponse)
def create_approval(payload: ExpenseApprovalCreate, db: Session = Depends(get_db)):
    return expense_approval_service.create_approval(db, payload)


@router.get("/{approval_id}", response_model=ExpenseApprovalResponse)
def get_approval(approval_id: int, db: Session = Depends(get_db)):
    approval = expense_approval_service.get_approval(db, approval_id)
    if not approval:
        raise HTTPException(status_code=404, detail="Approval not found")
    return approval


@router.get("/", response_model=List[ExpenseApprovalResponse])
def list_approvals(expense_id: int = None, db: Session = Depends(get_db)):
    return expense_approval_service.list_approvals(db, expense_id=expense_id)


@router.put("/{approval_id}", response_model=ExpenseApprovalResponse)
def update_approval(approval_id: int, payload: ExpenseApprovalUpdate, db: Session = Depends(get_db)):
    approval = expense_approval_service.update_approval(db, approval_id, payload)
    if not approval:
        raise HTTPException(status_code=404, detail="Approval not found")
    return approval


@router.delete("/{approval_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_approval(approval_id: int, db: Session = Depends(get_db)):
    success = expense_approval_service.delete_approval(db, approval_id)
    if not success:
        raise HTTPException(status_code=404, detail="Approval not found")
