from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from db import SessionLocal
from schemas.approval_workflow import ApprovalWorkflowCreate, ApprovalWorkflowUpdate, ApprovalWorkflowResponse
from services import approval_workflow_service

router = APIRouter(prefix="/approval-workflows", tags=["Approval Workflows"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/", response_model=ApprovalWorkflowResponse)
def create_workflow(payload: ApprovalWorkflowCreate, db: Session = Depends(get_db)):
    return approval_workflow_service.create_workflow(db, payload)


@router.get("/{workflow_id}", response_model=ApprovalWorkflowResponse)
def get_workflow(workflow_id: int, db: Session = Depends(get_db)):
    workflow = approval_workflow_service.get_workflow(db, workflow_id)
    if not workflow:
        raise HTTPException(status_code=404, detail="Workflow not found")
    return workflow


@router.get("/", response_model=List[ApprovalWorkflowResponse])
def list_workflows(company_id: int = None, db: Session = Depends(get_db)):
    return approval_workflow_service.list_workflows(db, company_id=company_id)


@router.put("/{workflow_id}", response_model=ApprovalWorkflowResponse)
def update_workflow(workflow_id: int, payload: ApprovalWorkflowUpdate, db: Session = Depends(get_db)):
    workflow = approval_workflow_service.update_workflow(db, workflow_id, payload)
    if not workflow:
        raise HTTPException(status_code=404, detail="Workflow not found")
    return workflow


@router.delete("/{workflow_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_workflow(workflow_id: int, db: Session = Depends(get_db)):
    success = approval_workflow_service.delete_workflow(db, workflow_id)
    if not success:
        raise HTTPException(status_code=404, detail="Workflow not found")
