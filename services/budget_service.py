from typing import Optional
from requests import Session
from db import SessionLocal
from models.models import Cost
from schemas.budget import CostCreate, CostOut, CostPaymentOut, CostUpdate
from utils.responses import success_response, error_response

class BudgetService:
    @staticmethod
    def create_budget(
        data: CostCreate,
        current_user,
        db: Session,
        photo_path: Optional[str] = None
    ) -> CostOut:
        
        budget = Cost(
            **data.dict(exclude={"photo"}),  # skip photo from schema
            user_id=current_user.id,
            photo=photo_path,
        )
        db.add(budget)
        db.flush()
        db.refresh(budget)

        paid_amount = sum(p.amount for p in budget.payments if p.isPaid)
        pending_amount = max(budget.estimate_amount - paid_amount, 0)
        balance_amount = budget.estimate_amount - paid_amount
        is_paid = paid_amount >= budget.estimate_amount
        payment_count = len(budget.payments)

        return CostOut(
            id=budget.id,
            name=budget.name,
            category=budget.category,
            estimate_amount=budget.estimate_amount,
            note=budget.note,
            photo=budget.photo,
            created_at=budget.created_at,
            paid_amount=paid_amount,
            pending_amount=pending_amount,
            balance_amount=balance_amount,
            is_paid=is_paid,
            payment_count=payment_count,
            payments=budget.payments,
        )

    @staticmethod
    def list_budgets(wedding_id: int, db: Session):
        # Fetch all costs for the wedding
        costs = db.query(Cost).filter(Cost.wedding_id == wedding_id).all()

        enriched_costs = []
        total_paid = 0.0
        total_estimate = 0.0

        for cost in costs:
            paid_amount = sum(p.amount for p in cost.payments if p.isPaid)  # ✅ use is_paid
            pending_amount = max(cost.estimate_amount - paid_amount, 0)
            balance_amount = cost.estimate_amount - paid_amount
            is_paid = paid_amount >= cost.estimate_amount
            payment_count = len(cost.payments)

            enriched_cost = CostOut(
                id=cost.id,
                name=cost.name,
                category=cost.category,
                estimate_amount=cost.estimate_amount,
                note=cost.note,
                vendor_id=cost.vendor_id,
                photo=cost.photo,
                created_at=cost.created_at,
                paid_amount=paid_amount,
                pending_amount=pending_amount,
                balance_amount=balance_amount,
                is_paid=is_paid,
                payment_count=payment_count,
                payments=[CostPaymentOut.model_validate(p) for p in cost.payments]
            )
            enriched_costs.append(enriched_cost)

            total_paid += paid_amount
            total_estimate += cost.estimate_amount

        overall_pending = max(total_estimate - total_paid, 0)
        overall_balance = total_estimate - total_paid

        return {
            "budgets": enriched_costs,
            "overall": {
                "total_estimate": total_estimate,
                "total_paid": total_paid,
                "total_pending": overall_pending,
                "total_balance": overall_balance
            }
        }

    @staticmethod
    def update_budget(
        budget_id: int,
        data: CostUpdate,
        current_user,
        db: Session,
        photo_path: Optional[str] = None
    ):
       
        budget = db.query(Cost).filter(Cost.id == budget_id).first()
        if not budget:
            raise ValueError("Budget not found")

        for field, value in data.dict(exclude_unset=True).items():
            setattr(budget, field, value)
        
        if photo_path:
            budget.photo = photo_path

        db.flush()
        db.refresh(budget)

        paid_amount = sum(getattr(p, "amount", 0.0) for p in budget.payments if getattr(p, "isPaid", False))
        pending_amount =  max(budget.estimate_amount - paid_amount, 0)  # can be negative if overpaid
        balance_amount = budget.estimate_amount - paid_amount
        is_paid = paid_amount >= budget.estimate_amount
        payment_count = len(budget.payments)

        enriched_budget = {
            **budget.__dict__,
            "paid_amount": paid_amount,
            "pending_amount": pending_amount,
            "balance_amount": balance_amount,
            "is_paid": is_paid,
            "payment_count": payment_count,
            "payments": budget.payments 
        }

        return enriched_budget

    @staticmethod
    def delete_budget(budget_id: int, current_user, db: Session):
        budget = db.query(Cost).filter(
            Cost.id == budget_id).first()
        if not budget:
            raise ValueError("Budget not found")

        db.delete(budget)
        db.flush()
