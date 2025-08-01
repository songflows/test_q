from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, Enum, Float, ForeignKey, JSON, Time
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum

from app.core.database import Base


class PointStatusEnum(enum.Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    MAINTENANCE = "maintenance"


class Point(Base):
    __tablename__ = "points"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Basic info
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    detailed_description = Column(Text, nullable=True)
    
    # Location
    address = Column(Text, nullable=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    
    # Status and settings
    status = Column(Enum(PointStatusEnum), default=PointStatusEnum.ACTIVE)
    
    # Working hours (JSON format: {"monday": {"start": "09:00", "end": "18:00"}, ...})
    working_hours = Column(JSON, nullable=True)
    
    # Queue settings
    accepts_online_orders = Column(Boolean, default=True)
    accepts_scheduled_orders = Column(Boolean, default=False)
    
    # Scheduling settings
    slot_duration_minutes = Column(Integer, default=30)  # Duration of each time slot
    slots_per_interval = Column(Integer, default=5)  # Number of available slots per interval
    advance_booking_days = Column(Integer, default=7)  # How many days in advance can book
    
    # Feature toggles
    enable_qr_code = Column(Boolean, default=True)
    require_phone_verification = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    owner = relationship("User", back_populates="owned_points")
    cashiers = relationship("Cashier", back_populates="point")
    orders = relationship("Order", back_populates="point")
    order_statuses = relationship("OrderStatus", back_populates="point")

    def __repr__(self):
        return f"<Point(id={self.id}, name='{self.name}', status='{self.status.value}')>"