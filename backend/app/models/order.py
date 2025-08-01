from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum

from app.core.database import Base


class OrderTypeEnum(enum.Enum):
    IMMEDIATE = "immediate"  # Заказ на текущее время
    SCHEDULED = "scheduled"  # Запланированный заказ


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    point_id = Column(Integer, ForeignKey("points.id"), nullable=False)
    cashier_id = Column(Integer, ForeignKey("cashiers.id"), nullable=True)
    
    # Order info
    order_number = Column(String(50), unique=True, index=True, nullable=False)
    order_type = Column(Enum(OrderTypeEnum), default=OrderTypeEnum.IMMEDIATE)
    
    # Description/notes
    description = Column(Text, nullable=True)
    customer_notes = Column(Text, nullable=True)
    
    # Scheduling
    scheduled_time = Column(DateTime(timezone=True), nullable=True)  # For scheduled orders
    
    # Current status
    current_status_id = Column(Integer, ForeignKey("order_statuses.id"), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="orders")
    point = relationship("Point", back_populates="orders")
    cashier = relationship("Cashier", back_populates="orders")
    current_status = relationship("OrderStatus", foreign_keys=[current_status_id])
    status_history = relationship("OrderStatusHistory", back_populates="order")
    
    def __repr__(self):
        return f"<Order(id={self.id}, number='{self.order_number}', type='{self.order_type.value}')>"


class OrderStatus(Base):
    __tablename__ = "order_statuses"

    id = Column(Integer, primary_key=True, index=True)
    point_id = Column(Integer, ForeignKey("points.id"), nullable=False)
    
    # Status info
    name = Column(String(100), nullable=False)  # в очереди, обслуживается, в работе, сборка, отменен
    description = Column(Text, nullable=True)
    color = Column(String(7), default="#007AFF")  # Hex color for UI
    
    # Order settings
    order_index = Column(Integer, default=0)  # Order in the sequence
    is_final = Column(Boolean, default=False)  # Terminal status (completed/cancelled)
    is_active = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    point = relationship("Point", back_populates="order_statuses")
    
    def __repr__(self):
        return f"<OrderStatus(id={self.id}, name='{self.name}', order_index={self.order_index})>"


class OrderStatusHistory(Base):
    __tablename__ = "order_status_history"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    status_id = Column(Integer, ForeignKey("order_statuses.id"), nullable=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    ended_at = Column(DateTime(timezone=True), nullable=True)
    
    # Additional info
    notes = Column(Text, nullable=True)
    changed_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    # Relationships
    order = relationship("Order", back_populates="status_history")
    status = relationship("OrderStatus")
    changed_by = relationship("User")
    
    def __repr__(self):
        return f"<OrderStatusHistory(id={self.id}, order_id={self.order_id}, status_id={self.status_id})>"