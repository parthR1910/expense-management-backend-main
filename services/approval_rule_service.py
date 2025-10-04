from sqlalchemy.orm import Session
from models.models import ApprovalRule
from schemas.approval_rule import ApprovalRuleCreate, ApprovalRuleUpdate

def create_rule(db: Session, payload: ApprovalRuleCreate) -> ApprovalRule:
    rule = ApprovalRule(
        company_id=payload.company_id,
        rule_type=payload.rule_type,
        percentage_required=payload.percentage_required,
        special_approver_role=payload.special_approver_role
    )
    db.add(rule)
    db.commit()
    db.refresh(rule)
    return rule

def get_rule(db: Session, rule_id: int) -> ApprovalRule:
    return db.query(ApprovalRule).filter(ApprovalRule.id == rule_id).first()

def list_rules(db: Session, company_id: int = None):
    query = db.query(ApprovalRule)
    if company_id:
        query = query.filter(ApprovalRule.company_id == company_id)
    return query.all()

def update_rule(db: Session, rule_id: int, payload: ApprovalRuleUpdate) -> ApprovalRule:
    rule = db.query(ApprovalRule).filter(ApprovalRule.id == rule_id).first()
    if not rule:
        return None
    for field, value in payload.dict(exclude_unset=True).items():
        setattr(rule, field, value)
    db.commit()
    db.refresh(rule)
    return rule

def delete_rule(db: Session, rule_id: int) -> bool:
    rule = db.query(ApprovalRule).filter(ApprovalRule.id == rule_id).first()
    if not rule:
        return False
    db.delete(rule)
    db.commit()
    return True
