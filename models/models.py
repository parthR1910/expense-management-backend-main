# models.py
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Text, Float, Enum, Time
from sqlalchemy.orm import relationship, backref
from db import Base
import datetime
import enum
import secrets
from utils.common_service import get_local_time

class RoleEnum(enum.Enum):
    creator = "creator"
    collaborator = "collaborator"
    guest = "guest"   # ✅ new role


class Device(Base):
    __tablename__ = "device"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String(45), nullable=True)       # VARCHAR(45)
    device_type = Column(Integer, nullable=True, default=0, comment="0 = IOS, 1 = Android") # INT(1)
    os_version = Column(String(10), nullable=True)      # VARCHAR(10)
    device_name = Column(String(45), nullable=True)     # VARCHAR(45)
    app_version = Column(Text, nullable=True)           # TEXT
    fcm_token = Column(Text, nullable=True)          # TEXT
    latitude = Column(Text, nullable=True)              # TEXT
    longitude = Column(Text, nullable=True)             # TEXT
    auth_token = Column(Text, nullable=True)            # TEXT
    # Foreign Key to User table
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=get_local_time)
    updated_at = Column(DateTime, default=get_local_time, onupdate=get_local_time)
    # Relationship with User
    user = relationship("User", back_populates="devices")


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True)
    hashed_password = Column(String(255), nullable=True)
    google_uid = Column(String(255), nullable=True)
    first_name = Column(String(100), nullable=True)
    last_name = Column(String(100), nullable=True)
    login_type = Column(Integer, index=True, nullable=False, default=0, comment="0 = google, 1 = email/pass, 2 = both",)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=get_local_time)
    photo = Column(String(255), nullable=True)
    weddings = relationship("Collaborator", back_populates="user")   # memberships
    owned_weddings = relationship(
        "Wedding",
        back_populates="owner",
        foreign_keys="Wedding.owner_id"  # ✅ specify correct FK
    )
    devices = relationship("Device", back_populates="user")
    costs = relationship("Cost", back_populates="user")
    payments = relationship("CostPayment", back_populates="user", cascade="all, delete-orphan")  

    last_active_wedding_id = Column(Integer, ForeignKey("weddings.id"), nullable=True)
    last_active_wedding = relationship(
        "Wedding",
        foreign_keys=[last_active_wedding_id]  # ✅ prevent ambiguity
    )


class Wedding(Base):
    __tablename__ = "weddings"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(150), nullable=True)
    name = Column(String(100), nullable=True)
    spouse_name = Column(String(100), nullable=True)
    wedding_date = Column(DateTime, nullable=True)
    budget_total = Column(Float, default=0.0)

    # ✅ separate codes for guest and collaborator
    guest_code = Column(String(50), unique=True, index=True, default=lambda: secrets.token_urlsafe(6))
    collaborator_code = Column(String(50), unique=True, index=True, default=lambda: secrets.token_urlsafe(6))

    created_at = Column(DateTime, default=get_local_time)

    # ✅ FK to User (owner)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    owner = relationship(
        "User",
        back_populates="owned_weddings",
        foreign_keys=[owner_id]
    )

    # Existing relations
    members = relationship("Collaborator", back_populates="wedding")
    tasks = relationship("Task", back_populates="wedding")
    costs = relationship("Cost", back_populates="wedding")
    vendors = relationship("Vendor", back_populates="wedding")
    schedules = relationship("Schedule", back_populates="wedding")
    messages = relationship("Message", back_populates="wedding")
    guests = relationship("Guest", back_populates="wedding")


class Collaborator(Base):
    __tablename__ = "collaborator"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    wedding_id = Column(Integer, ForeignKey("weddings.id"))
    role = Column(Enum(RoleEnum), default=RoleEnum.collaborator)
    joined_at = Column(DateTime, default=get_local_time)

    user = relationship("User", back_populates="weddings")
    wedding = relationship("Wedding", back_populates="members")

class Task(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, index=True)
    wedding_id = Column(Integer, ForeignKey("weddings.id"))
    parent_id = Column(Integer, ForeignKey("tasks.id"), nullable=True)
    name = Column(String(150), nullable=False)                        # VARCHAR(150)
    category = Column(String(100), nullable=True)                     # VARCHAR(100)
    description = Column(Text, nullable=True)
    start_time = Column(Time, nullable=True)# TEXT
    due_date = Column(DateTime, nullable=True)
    completed = Column(Boolean, default=False)
    photo = Column(String(255), nullable=True)                        # URL or file path
    created_at = Column(DateTime, default=get_local_time)

    wedding = relationship("Wedding", back_populates="tasks")
    subtasks = relationship(
    "Task",
    backref=backref("parent", remote_side=[id]),
    cascade="all, delete-orphan"
    )

class Cost(Base):
    __tablename__ = "cost"
    id = Column(Integer, primary_key=True, index=True)
    wedding_id = Column(Integer, ForeignKey("weddings.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    vendor_id = Column(Integer, ForeignKey("vendors.id",ondelete="CASCADE"), nullable=True)
    name = Column(String(150), nullable=False)
    category = Column(String(100), nullable=True)
    estimate_amount = Column(Float, default=0.0)
    note = Column(Text, nullable=True)
    photo = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=get_local_time)

    wedding = relationship("Wedding", back_populates="costs")
    user = relationship("User", back_populates="costs")  # ✅ corrected
    vendor = relationship("Vendor", back_populates="costs")
    payments = relationship("CostPayment", back_populates="cost", cascade="all, delete-orphan")

class Vendor(Base):
    __tablename__ = "vendors"
    id = Column(Integer, primary_key=True, index=True)
    wedding_id = Column(Integer, ForeignKey("weddings.id"))
    name = Column(String(150), nullable=False)                        # VARCHAR(150)
    category = Column(String(100), nullable=True)                     # VARCHAR(100)
    phone = Column(String(20), nullable=True)                         # VARCHAR(20)
    email = Column(String(255), nullable=True)                        # VARCHAR(255)
    site = Column(String(255), nullable=True)                         # URL
    address = Column(String(255), nullable=True)
    amount = Column(Float, default=0.0)
    status = Column(String(50), default="Pending")                    # Reserved/Pending/Rejected
    note = Column(Text, nullable=True)
    created_at = Column(DateTime, default=get_local_time)

    wedding = relationship("Wedding", back_populates="vendors")
    costs = relationship("Cost", back_populates="vendor",cascade="all, delete-orphan",
        passive_deletes=True)
    payments = relationship("CostPayment", back_populates="vendor", cascade="all, delete-orphan")

class Guest(Base):
    __tablename__ = "guests"

    id = Column(Integer, primary_key=True, index=True)
    wedding_id = Column(Integer, ForeignKey("weddings.id"))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)   # link guest to user
    task_ids = Column(String(300), nullable=True)
   # 🔗 replaces event_category

    # Personal details
    first_name = Column(String(150), nullable=False)                   # ✅ renamed "name" to first_name
    last_name = Column(String(150), nullable=True)
    gender = Column(String(20), nullable=True)                         # Male/Female/Other
    age_criteria = Column(String(20), nullable=True, comment="adult/child")  # ✅ for Adult/Child

    # Contact info
    phone = Column(String(20), nullable=True)
    email = Column(String(255), nullable=True)
    address = Column(Text, nullable=True)

    # Additional info
    note = Column(Text, nullable=True)
    group_category = Column(String(100), nullable=True)                # e.g., Bride side / Groom side

    created_at = Column(DateTime, default=get_local_time)

    # Relationships
    wedding = relationship("Wedding", back_populates="guests")
    user = relationship("User")  
    # Helper to convert string <-> list
    def get_task_ids(self):
        return [int(tid) for tid in self.task_ids.split(",")] if self.task_ids else []

    def set_task_ids(self, ids: list[int]):
        self.task_ids = ",".join(map(str, ids))

class Schedule(Base):
    __tablename__ = "schedules"
    id = Column(Integer, primary_key=True, index=True)
    wedding_id = Column(Integer, ForeignKey("weddings.id"))
    title = Column(String(150), nullable=False)                       # Event title
    category = Column(String(100), nullable=True)                     # Wedding, Party etc
    date = Column(DateTime, nullable=False)
    time = Column(String(20), nullable=True)                          # HH:MM AM/PM
    created_at = Column(DateTime, default=get_local_time)

    wedding = relationship("Wedding", back_populates="schedules")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    wedding_id = Column(Integer, ForeignKey("weddings.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    content = Column(Text, nullable=False)                            # Message text
    created_at = Column(DateTime, default=get_local_time)

    wedding = relationship("Wedding", back_populates="messages")

class CostPayment(Base):
    __tablename__ = "cost_payments"

    id = Column(Integer, primary_key=True, index=True)
    cost_id = Column(Integer, ForeignKey("cost.id", ondelete="CASCADE"))
    vendor_id = Column(Integer, ForeignKey("vendors.id", ondelete="SET NULL"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))

    amount = Column(Float, nullable=False, default=0.0)
    note = Column(Text, nullable=True)
    name = Column(String(150), nullable=False)  
    isPaid = Column(Boolean, default=True)
    photo = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=get_local_time)
    paymentdate = Column(DateTime, default=get_local_time)

    # 🔗 Relationships
    cost = relationship("Cost", back_populates="payments")
    vendor = relationship("Vendor", back_populates="payments")
    user = relationship("User", back_populates="payments")
