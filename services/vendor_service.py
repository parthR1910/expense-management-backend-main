from schemas.budget import CostPaymentOut
from schemas.vendor import VendorOut
from sqlalchemy.orm import Session
from models.models import Cost, CostPayment, Vendor
from schemas import VendorCreate, VendorUpdate
from sqlalchemy import func


class VendorService:
    @staticmethod
    def create_vendor(payload: VendorCreate, current_user, db: Session):
        vendor = Vendor(
            name=payload.name,
            category=payload.category,
            wedding_id=payload.wedding_id,
            phone=payload.phone,
            email=payload.email,
            site=payload.site,
            address=payload.address,
            amount=payload.amount,
            status=payload.status,
            note=payload.note,
        )
        db.add(vendor)
        db.flush()   # so vendor.id is available

        # If add_budget = True → also create a Cost entry
        if payload.status == "reserved" and payload.add_budget:
            cost = Cost(
                wedding_id=payload.wedding_id,
                user_id=current_user.id,
                vendor_id=vendor.id,   # link to this vendor
                name=payload.name,     # cost name same as vendor
                category=payload.category,
                estimate_amount=payload.amount or 0.0,
                note=payload.note,
                photo=None
            )
            db.add(cost)

        db.commit()
        db.refresh(vendor)
        return vendor

    @staticmethod
    def list_vendors(wedding_id: int, db: Session):
        vendors = db.query(Vendor).filter(Vendor.wedding_id == wedding_id).all()

        # Status counts
        total_reserved = db.query(func.count(Vendor.id)).filter(
            Vendor.wedding_id == wedding_id, Vendor.status == "Reserved"
        ).scalar()
        total_pending = db.query(func.count(Vendor.id)).filter(
            Vendor.wedding_id == wedding_id, Vendor.status == "Pending"
        ).scalar()
        total_rejected = db.query(func.count(Vendor.id)).filter(
            Vendor.wedding_id == wedding_id, Vendor.status == "Rejected"
        ).scalar()

        # Wedding-level financials
        total_amount = (
            db.query(func.coalesce(func.sum(Cost.estimate_amount), 0.0))
            .filter(Cost.wedding_id == wedding_id, Cost.vendor_id.isnot(None))
            .scalar()
        )

        paid_amount = (
            db.query(func.coalesce(func.sum(CostPayment.amount), 0.0))
            .join(Cost, Cost.id == CostPayment.cost_id)
            .filter(Cost.wedding_id == wedding_id, Cost.vendor_id.isnot(None))
            .scalar()
        )

        pending_amount = total_amount - paid_amount

        # Vendor-level enrichments
        enriched_vendors = []
        for v in vendors:
            cost = v.costs[0] if v.costs else None

            vendor_total_amount = sum(c.estimate_amount for c in v.costs)
            vendor_paid_amount = sum(
                p.amount for c in v.costs for p in c.payments if p.isPaid
            )
            vendor_pending_amount = vendor_total_amount - vendor_paid_amount
            vendor_balance_amount = vendor_pending_amount  # allow negative if overpaid

            enriched_vendors.append(
                VendorOut(
                    **v.__dict__,
                    cost_id=cost.id if cost else None,
                    payments=[CostPaymentOut.model_validate(p) for c in v.costs for p in c.payments],
                    total_amount=vendor_total_amount,
                    paid_amount=vendor_paid_amount,
                    pending_amount=max(vendor_pending_amount, 0),  # no negative
                    balance_amount=vendor_balance_amount,          # allow negative
                )
            )

        return {
            "total_reserved": total_reserved or 0,
            "total_pending": total_pending or 0,
            "total_rejected": total_rejected or 0,
            "total_amount": float(total_amount or 0),
            "paid_amount": float(paid_amount or 0),
            "pending_amount": float(pending_amount or 0),
            "vendors": enriched_vendors,
        }
    @staticmethod
    def update_vendor(vendor_id: int, data: VendorUpdate, current_user, db: Session):
        vendor = db.query(Vendor).filter(
            Vendor.id == vendor_id,
        ).first()
        if not vendor:
            return None

        # ✅ Update vendor fields
        for field, value in data.dict(exclude_unset=True).items():
            setattr(vendor, field, value)

        # ✅ Handle Cost depending on status
        cost = db.query(Cost).filter(
            Cost.vendor_id == vendor_id,
            Cost.wedding_id == vendor.wedding_id
        ).first()

        if data.status == "reserved":
            if cost:
                # Update existing cost
                cost.estimate_amount = data.amount or vendor.amount or 0.0
                cost.name = vendor.name
                cost.category = vendor.category
                cost.note = vendor.note
            else:
                # Create cost if not exists
                cost = Cost(
                    vendor_id=vendor.id,
                    wedding_id=vendor.wedding_id,
                    user_id=current_user.id,
                    name=vendor.name,
                    category=vendor.category,
                    estimate_amount=data.amount or vendor.amount or 0.0,
                    note=vendor.note,
                )
                db.add(cost)

        elif data.status in ["pending", "rejected"]:
            if cost:
                db.delete(cost)  # cascade → cost payments also deleted

        db.commit()
        db.refresh(vendor)
        return vendor

    @staticmethod
    def delete_vendor(vendor_id: int, current_user, db: Session):
        vendor = db.query(Vendor).filter(
            Vendor.id == vendor_id,
        ).first()
        if not vendor:
            return None

        db.delete(vendor)
        db.commit()
        return True
