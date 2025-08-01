from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class OrderTypeEnum(str, Enum):
    IMMEDIATE = "immediate"
    SCHEDULED = "scheduled"


class OrderBase(BaseModel):
    description: Optional[str] = None
    customer_notes: Optional[str] = None


class OrderCreate(OrderBase):
    point_id: int
    cashier_id: Optional[int] = None
    order_type: OrderTypeEnum = OrderTypeEnum.IMMEDIATE
    scheduled_time: Optional[datetime] = None


class OrderUpdate(BaseModel):
    description: Optional[str] = None
    customer_notes: Optional[str] = None
    scheduled_time: Optional[datetime] = None
    current_status_id: Optional[int] = None


class OrderInDB(OrderBase):
    id: int
    user_id: int
    point_id: int
    cashier_id: Optional[int] = None
    order_number: str
    order_type: OrderTypeEnum
    scheduled_time: Optional[datetime] = None
    current_status_id: Optional[int] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class Order(OrderInDB):
    pass


class OrderPublic(BaseModel):
    """Public order info for display"""
    id: int
    order_number: str
    order_type: OrderTypeEnum
    scheduled_time: Optional[datetime] = None
    current_status: Optional["OrderStatusPublic"] = None
    created_at: datetime

    class Config:
        from_attributes = True


class OrderWithDetails(OrderInDB):
    """Order with full details"""
    user: Optional["UserProfile"] = None
    point: Optional["PointPublic"] = None
    cashier: Optional["CashierInDB"] = None
    current_status: Optional["OrderStatusInDB"] = None
    status_history: List["OrderStatusHistoryInDB"] = []

    class Config:
        from_attributes = True


# Order Status schemas
class OrderStatusBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    color: str = Field("#007AFF", regex=r"^#[0-9A-Fa-f]{6}$")


class OrderStatusCreate(OrderStatusBase):
    point_id: int
    order_index: int = 0
    is_final: bool = False


class OrderStatusUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    color: Optional[str] = Field(None, regex=r"^#[0-9A-Fa-f]{6}$")
    order_index: Optional[int] = None
    is_final: Optional[bool] = None
    is_active: Optional[bool] = None


class OrderStatusInDB(OrderStatusBase):
    id: int
    point_id: int
    order_index: int
    is_final: bool
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class OrderStatus(OrderStatusInDB):
    pass


class OrderStatusPublic(BaseModel):
    """Public status info for display"""
    id: int
    name: str
    description: Optional[str] = None
    color: str
    order_index: int
    is_final: bool

    class Config:
        from_attributes = True


# Order Status History schemas
class OrderStatusHistoryBase(BaseModel):
    notes: Optional[str] = None


class OrderStatusHistoryCreate(OrderStatusHistoryBase):
    order_id: int
    status_id: int
    changed_by_user_id: Optional[int] = None


class OrderStatusHistoryUpdate(BaseModel):
    ended_at: Optional[datetime] = None
    notes: Optional[str] = None


class OrderStatusHistoryInDB(OrderStatusHistoryBase):
    id: int
    order_id: int
    status_id: int
    created_at: datetime
    ended_at: Optional[datetime] = None
    changed_by_user_id: Optional[int] = None

    class Config:
        from_attributes = True


class OrderStatusHistory(OrderStatusHistoryInDB):
    pass


class OrderStatusHistoryWithDetails(OrderStatusHistoryInDB):
    """History with status and user details"""
    status: Optional[OrderStatusPublic] = None
    changed_by: Optional["UserProfile"] = None

    class Config:
        from_attributes = True


# Queue management schemas
class QueuePosition(BaseModel):
    order_id: int
    position: int
    estimated_wait_time_minutes: Optional[int] = None


class QueueStatus(BaseModel):
    point_id: int
    cashier_id: Optional[int] = None
    total_orders: int
    current_orders: List[OrderPublic] = []
    queue: List[QueuePosition] = []


class OrderStatusTransition(BaseModel):
    order_id: int
    new_status_id: int
    notes: Optional[str] = None


class AvailableTimeSlot(BaseModel):
    datetime: datetime
    available_slots: int
    total_slots: int


class TimeSlotAvailability(BaseModel):
    point_id: int
    date: str  # YYYY-MM-DD format
    slots: List[AvailableTimeSlot] = []


# Forward reference resolution
from app.schemas.user import UserProfile
from app.schemas.point import PointPublic
from app.schemas.cashier import CashierInDB

OrderPublic.model_rebuild()
OrderWithDetails.model_rebuild()
OrderStatusHistoryWithDetails.model_rebuild()