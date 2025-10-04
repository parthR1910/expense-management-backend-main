from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from db import SessionLocal
from schemas.approval_rule import ApprovalRuleCreate, ApprovalRuleUpdate, ApprovalRuleResponse
from services import approval_rule_service

router = APIRouter(prefix="/approval-rules", tags=["Approval Rules"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/", response_model=ApprovalRuleResponse)
def create_rule(payload: ApprovalRuleCreate, db: Session = Depends(get_db)):
    return approval_rule_service.create_rule(db, payload)


@router.get("/{rule_id}", response_model=ApprovalRuleResponse)
def get_rule(rule_id: int, db: Session = Depends(get_db)):
    rule = approval_rule_service.get_rule(db, rule_id)
    if not rule:
        raise HTTPException(status_code=404, detail="Rule not found")
    return rule


@router.get("/", response_model=List[ApprovalRuleResponse])
def list_rules(company_id: int = None, db: Session = Depends(get_db)):
    return approval_rule_service.list_rules(db, company_id=company_id)


@router.put("/{rule_id}", response_model=ApprovalRuleResponse)
def update_rule(rule_id: int, payload: ApprovalRuleUpdate, db: Session = Depends(get_db)):
    rule = approval_rule_service.update_rule(db, rule_id, payload)
    if not rule:
        raise HTTPException(status_code=404, detail="Rule not found")
    return rule


@router.delete("/{rule_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_rule(rule_id: int, db: Session = Depends(get_db)):
    success = approval_rule_service.delete_rule(db, rule_id)
    if not success:
        raise HTTPException(status_code=404, detail="Rule not found")
