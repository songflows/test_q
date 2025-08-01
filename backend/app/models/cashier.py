from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum

from app.core.database import Base


class CashierStatusEnum(enum.Enum):
    AVAILABLE = "available"
    BUSY = "busy"
    OFFLINE = "offline"
    BREAK = "break"


class Cashier(Base):
    __tablename__ = "cashiers"

    id = Column(Integer, primary_key=True, index=True)
    point_id = Column(Integer, ForeignKey("points.id"), nullable=False)
    assigned_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    # Cashier info
    number = Column(String(50), nullable=False)  # Cashier number/identifier
    name = Column(String(255), nullable=False)  # Display name
    status = Column(Enum(CashierStatusEnum), default=CashierStatusEnum.AVAILABLE)
    
    # Settings
    is_active = Column(Boolean, default=True)
    max_concurrent_orders = Column(Integer, default=1)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_activity = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    point = relationship("Point", back_populates="cashiers")
    assigned_user = relationship("User", back_populates="cashier_assignments")
    orders = relationship("Order", back_populates="cashier")
    
    def __repr__(self):
        return f"<Cashier(id={self.id}, number='{self.number}', name='{self.name}', status='{self.status.value}')>"