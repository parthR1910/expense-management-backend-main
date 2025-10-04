from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Text, Float, Enum
from sqlalchemy.orm import relationship
from db import Base
import datetime
import enum
from utils.common_service import get_local_time


# --------- Role Enum ---------
class RoleEnum(str, enum.Enum):
    admin = "Admin"
    manager = "Manager"
    employee = "Employee"


# --------- Expense Status Enum ---------
class ExpenseStatus(str, enum.Enum):
    pending = "Pending"
    approved = "Approved"
    rejected = "Rejected"


# --------- User ---------
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"))
    email = Column(String(255), unique=True, index=True)
    hashed_password = Column(String(255), nullable=True)
    first_name = Column(String(100), nullable=True)
    last_name = Column(String(100), nullable=True)
    role = Column(Enum(RoleEnum), default=RoleEnum.employee)
    manager_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=get_local_time)

    # 🔗 Relationships
    company = relationship("Company", back_populates="users")
    devices = relationship("Device", back_populates="user")
    expenses = relationship("Expense", back_populates="employee")


# --------- Device ---------
class Device(Base):
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String(45), nullable=True)
    device_type = Column(Integer, nullable=True, default=0, comment="0 = IOS, 1 = Android")
    os_version = Column(String(10), nullable=True)
    device_name = Column(String(45), nullable=True)
    app_version = Column(Text, nullable=True)
    fcm_token = Column(Text, nullable=True)
    latitude = Column(Text, nullable=True)
    longitude = Column(Text, nullable=True)
    auth_token = Column(Text, nullable=True)

    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=get_local_time)
    updated_at = Column(DateTime, default=get_local_time, onupdate=get_local_time)

    user = relationship("User", back_populates="devices")


# --------- Company ---------
class Company(Base):
    __tablename__ = "companies"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    country = Column(String(100), nullable=True)
    currency_code = Column(String(10), nullable=False)
    created_at = Column(DateTime, default=get_local_time)

    users = relationship("User", back_populates="company")
    expenses = relationship("Expense", back_populates="company")
    workflows = relationship("ApprovalWorkflow", back_populates="company")
    rules = relationship("ApprovalRule", back_populates="company")


# --------- Expense ---------
class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(Integer, ForeignKey("users.id"))
    company_id = Column(Integer, ForeignKey("companies.id"))
    amount_original = Column(Float)
    currency_original = Column(String(10))
    amount_in_company_currency = Column(Float)
    category = Column(String(100))
    description = Column(Text)
    date = Column(DateTime, default=get_local_time)
    receipt_url = Column(String(255), nullable=True)
    status = Column(Enum(ExpenseStatus), default=ExpenseStatus.pending)
    current_step = Column(Integer, default=1)
    created_at = Column(DateTime, default=get_local_time)

    # 🔗 Relationships
    employee = relationship("User", back_populates="expenses")
    company = relationship("Company", back_populates="expenses")
    approvals = relationship("ExpenseApproval", back_populates="expense")


# --------- Approval Workflow ---------
class ApprovalWorkflow(Base):
    __tablename__ = "approval_workflows"

    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"))
    step_number = Column(Integer)
    role_required = Column(String(50))  # Manager, Finance, Director, CFO
    sequence_order = Column(Integer)
    created_at = Column(DateTime, default=get_local_time)

    company = relationship("Company", back_populates="workflows")


# --------- Expense Approval ---------
class ExpenseApproval(Base):
    __tablename__ = "expense_approvals"

    id = Column(Integer, primary_key=True, index=True)
    expense_id = Column(Integer, ForeignKey("expenses.id"))
    approver_id = Column(Integer, ForeignKey("users.id"))
    step_number = Column(Integer)
    status = Column(Enum(ExpenseStatus), default=ExpenseStatus.pending)
    comments = Column(Text, nullable=True)
    approved_at = Column(DateTime, nullable=True)

    # 🔗 Relationships
    expense = relationship("Expense", back_populates="approvals")
    approver = relationship("User")


# --------- Approval Rules ---------
class ApprovalRule(Base):
    __tablename__ = "approval_rules"

    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"))
    rule_type = Column(String(50))  # percentage / special / hybrid
    percentage_required = Column(Integer, nullable=True)
    special_approver_role = Column(String(50), nullable=True)  # e.g., CFO
    created_at = Column(DateTime, default=get_local_time)

    company = relationship("Company", back_populates="rules")
