from sqlalchemy.orm import Session
from models.models import ApprovalWorkflow
from schemas.approval_workflow import ApprovalWorkflowCreate, ApprovalWorkflowUpdate

def create_workflow(db: Session, payload: ApprovalWorkflowCreate) -> ApprovalWorkflow:
    workflow = ApprovalWorkflow(
        company_id=payload.company_id,
        step_number=payload.step_number,
        role_required=payload.role_required,
        sequence_order=payload.sequence_order
    )
    db.add(workflow)
    db.commit()
    db.refresh(workflow)
    return workflow

def get_workflow(db: Session, workflow_id: int) -> ApprovalWorkflow:
    return db.query(ApprovalWorkflow).filter(ApprovalWorkflow.id == workflow_id).first()

def list_workflows(db: Session, company_id: int = None):
    query = db.query(ApprovalWorkflow)
    if company_id:
        query = query.filter(ApprovalWorkflow.company_id == company_id)
    return query.order_by(ApprovalWorkflow.sequence_order).all()

def update_workflow(db: Session, workflow_id: int, payload: ApprovalWorkflowUpdate) -> ApprovalWorkflow:
    workflow = db.query(ApprovalWorkflow).filter(ApprovalWorkflow.id == workflow_id).first()
    if not workflow:
        return None
    for field, value in payload.dict(exclude_unset=True).items():
        setattr(workflow, field, value)
    db.commit()
    db.refresh(workflow)
    return workflow

def delete_workflow(db: Session, workflow_id: int) -> bool:
    workflow = db.query(ApprovalWorkflow).filter(ApprovalWorkflow.id == workflow_id).first()
    if not workflow:
        return False
    db.delete(workflow)
    db.commit()
    return True
