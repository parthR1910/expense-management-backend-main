from sqlalchemy.orm import Session
from models.models import Company
from schemas.company import CompanyCreate, CompanyUpdate

def get_company(db: Session, company_id: int):
    return db.query(Company).filter(Company.id == company_id).first()

def get_all_companies(db: Session):
    return db.query(Company).all()

def create_company(db: Session, payload: CompanyCreate):
    company = Company(**payload.dict())
    db.add(company)
    db.commit()
    db.refresh(company)
    return company

def update_company(db: Session, company_id: int, payload: CompanyUpdate):
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        return None
    for key, value in payload.dict(exclude_unset=True).items():
        setattr(company, key, value)
    db.commit()
    db.refresh(company)
    return company

def delete_company(db: Session, company_id: int):
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        return False
    db.delete(company)
    db.commit()
    return True
