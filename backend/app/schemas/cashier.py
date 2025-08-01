from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List
from datetime import datetime
from enum import Enum


class CashierStatusEnum(str, Enum):
    AVAILABLE = "available"
    BUSY = "busy"
    OFFLINE = "offline"
    BREAK = "break"


class CashierBase(BaseModel):
    number: str = Field(..., min_length=1, max_length=50)
    name: str = Field(..., min_length=1, max_length=255)


class CashierCreate(CashierBase):
    point_id: int
    assigned_user_email: Optional[EmailStr] = None
    max_concurrent_orders: int = Field(1, ge=1, le=10)


class CashierUpdate(BaseModel):
    number: Optional[str] = Field(None, min_length=1, max_length=50)
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    status: Optional[CashierStatusEnum] = None
    assigned_user_email: Optional[EmailStr] = None
    max_concurrent_orders: Optional[int] = Field(None, ge=1, le=10)
    is_active: Optional[bool] = None


class CashierInDB(CashierBase):
    id: int
    point_id: int
    assigned_user_id: Optional[int] = None
    status: CashierStatusEnum
    is_active: bool
    max_concurrent_orders: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    last_activity: Optional[datetime] = None

    class Config:
        from_attributes = True


class Cashier(CashierInDB):
    pass


class CashierWithUser(CashierInDB):
    """Cashier with assigned user info"""
    assigned_user: Optional["UserProfile"] = None

    class Config:
        from_attributes = True


class CashierAssignUser(BaseModel):
    user_email: EmailStr


class CashierStatusUpdate(BaseModel):
    status: CashierStatusEnum


class CashierCurrentOrders(BaseModel):
    cashier_id: int
    current_orders: List["OrderPublic"] = []
    max_concurrent_orders: int
    is_available: bool

    class Config:
        from_attributes = True


# Forward reference resolution
from app.schemas.user import UserProfile
from app.schemas.order import OrderPublic

CashierWithUser.model_rebuild()
CashierCurrentOrders.model_rebuild()