from requests import Session
from sqlalchemy import func
from models.models import Cost, CostPayment, User, Vendor


class PaymentService:
    @staticmethod
    def create_payment(name: str, isPaid:bool,photo_url,cost_id: int,paymentdate: str, vendor_id: int | None, user_id: int, amount: float, db: Session, note: str | None = None,):
        cost = db.query(Cost).filter(Cost.id == cost_id).first()
        if not cost:
            raise ValueError("Cost not found")

        vendor = None
        if vendor_id:
            vendor = db.query(Vendor).filter(Vendor.id == vendor_id).first()
            if not vendor:
                raise ValueError("Vendor not found")

        payment = CostPayment(
            name=name,
            isPaid=isPaid,
            photo=photo_url,      
            cost_id=cost_id,
            vendor_id=vendor_id,
            user_id=user_id,
            amount=amount,
            note=note,
            paymentdate=paymentdate
            
        )
        db.add(payment)
        db.flush()
        db.refresh(payment)

        return payment

    @staticmethod
    def list_payments_for_cost(cost_id: int, db: Session):
        return db.query(CostPayment).filter(CostPayment.cost_id == cost_id).all()

    @staticmethod
    def get_total_paid(cost_id: int, db: Session):
        total = db.query(func.sum(CostPayment.amount)).filter(CostPayment.cost_id == cost_id).scalar() or 0.0
        return total

    @staticmethod
    def update_payment(
        payment_id: int,
        db: Session,
        user_id: int,
        name: str | None = None,
        amount: float | None = None,
        isPaid: bool | None = None,
        note: str | None = None,
        photo_url: str | None = None
    ):
        payment = db.query(CostPayment).filter(CostPayment.id == payment_id).first()
        if not payment:
            raise ValueError("Payment not found")

        if payment.user_id != user_id:
            raise ValueError("Not authorized to update this payment")

        # Update fields if provided
        if name is not None:
            payment.name = name
        if amount is not None:
            payment.amount = amount
        if isPaid is not None:
            payment.is_paid = isPaid
        if note is not None:
            payment.note = note
        if photo_url is not None:
            payment.photo = photo_url

        db.flush()
        db.refresh(payment)
        return payment
    
    @staticmethod
    def delete_payment(payment_id: int, db: Session, current_user: User):
        payment = db.query(CostPayment).filter(CostPayment.id == payment_id).first()

        if not payment:
            raise ValueError("Payment not found")


        db.delete(payment)
        db.flush()  # flush so Cost updates immediately

        return True