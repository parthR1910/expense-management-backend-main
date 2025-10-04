from sqlalchemy.orm import Session
from models.models import ExpenseApproval
from schemas.expense_approval import ExpenseApprovalCreate, ExpenseApprovalUpdate
from datetime import datetime

def create_approval(db: Session, payload: ExpenseApprovalCreate) -> ExpenseApproval:
    approval = ExpenseApproval(
        expense_id=payload.expense_id,
        approver_id=payload.approver_id,
        step_number=payload.step_number,
        status=payload.status,
        comments=payload.comments
    )
    db.add(approval)
    db.commit()
    db.refresh(approval)
    return approval

def get_approval(db: Session, approval_id: int) -> ExpenseApproval:
    return db.query(ExpenseApproval).filter(ExpenseApproval.id == approval_id).first()

def list_approvals(db: Session, expense_id: int = None):
    query = db.query(ExpenseApproval)
    if expense_id:
        query = query.filter(ExpenseApproval.expense_id == expense_id)
    return query.all()

def update_approval(db: Session, approval_id: int, payload: ExpenseApprovalUpdate) -> ExpenseApproval:
    approval = db.query(ExpenseApproval).filter(ExpenseApproval.id == approval_id).first()
    if not approval:
        return None
    for field, value in payload.dict(exclude_unset=True).items():
        setattr(approval, field, value)
    if payload.status and payload.status != approval.status:
        approval.approved_at = datetime.utcnow() if payload.status == ExpenseApproval.status.approved else approval.approved_at
    db.commit()
    db.refresh(approval)
    return approval

def delete_approval(db: Session, approval_id: int) -> bool:
    approval = db.query(ExpenseApproval).filter(ExpenseApproval.id == approval_id).first()
    if not approval:
        return False
    db.delete(approval)
    db.commit()
    return True
