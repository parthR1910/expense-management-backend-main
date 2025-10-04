from sqlalchemy.orm import Session
from models.models import Expense
from schemas.expense import ExpenseCreate, ExpenseUpdate

def create_expense(db: Session, payload: ExpenseCreate) -> Expense:
    expense = Expense(
        company_id=payload.company_id,
        employee_id=payload.employee_id,
        amount_original=payload.amount_original,
        currency_original=payload.currency_original,
        amount_in_company_currency=payload.amount_in_company_currency,
        category=payload.category,
        description=payload.description,
        date=payload.date,
        receipt_url=payload.receipt_url
    )
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense


def get_expense(db: Session, expense_id: int) -> Expense:
    return db.query(Expense).filter(Expense.id == expense_id).first()


def list_expenses(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Expense).offset(skip).limit(limit).all()


def update_expense(db: Session, expense_id: int, payload: ExpenseUpdate) -> Expense:
    expense = db.query(Expense).filter(Expense.id == expense_id).first()
    if not expense:
        return None

    for field, value in payload.dict(exclude_unset=True).items():
        setattr(expense, field, value)

    db.commit()
    db.refresh(expense)
    return expense


def delete_expense(db: Session, expense_id: int) -> bool:
    expense = db.query(Expense).filter(Expense.id == expense_id).first()
    if not expense:
        return False
    db.delete(expense)
    db.commit()
    return True
