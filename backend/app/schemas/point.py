from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime, time
from enum import Enum


class PointStatusEnum(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    MAINTENANCE = "maintenance"


class WorkingHours(BaseModel):
    start: time
    end: time
    is_closed: bool = False


class PointBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    detailed_description: Optional[str] = None
    address: str = Field(..., min_length=1)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)


class PointCreate(PointBase):
    # Working hours as dict: {"monday": {"start": "09:00", "end": "18:00", "is_closed": false}, ...}
    working_hours: Optional[Dict[str, Dict[str, Any]]] = None
    
    # Queue settings
    accepts_online_orders: bool = True
    accepts_scheduled_orders: bool = False
    
    # Scheduling settings
    slot_duration_minutes: int = Field(30, ge=15, le=120)
    slots_per_interval: int = Field(5, ge=1, le=50)
    advance_booking_days: int = Field(7, ge=1, le=30)
    
    # Feature toggles
    enable_qr_code: bool = True
    require_phone_verification: bool = False


class PointUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    detailed_description: Optional[str] = None
    address: Optional[str] = Field(None, min_length=1)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    status: Optional[PointStatusEnum] = None
    working_hours: Optional[Dict[str, Dict[str, Any]]] = None
    accepts_online_orders: Optional[bool] = None
    accepts_scheduled_orders: Optional[bool] = None
    slot_duration_minutes: Optional[int] = Field(None, ge=15, le=120)
    slots_per_interval: Optional[int] = Field(None, ge=1, le=50)
    advance_booking_days: Optional[int] = Field(None, ge=1, le=30)
    enable_qr_code: Optional[bool] = None
    require_phone_verification: Optional[bool] = None


class PointInDB(PointBase):
    id: int
    owner_id: int
    status: PointStatusEnum
    working_hours: Optional[Dict[str, Any]] = None
    accepts_online_orders: bool
    accepts_scheduled_orders: bool
    slot_duration_minutes: int
    slots_per_interval: int
    advance_booking_days: int
    enable_qr_code: bool
    require_phone_verification: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class Point(PointInDB):
    pass


class PointPublic(BaseModel):
    """Public point info for QR codes and map display"""
    id: int
    name: str
    description: Optional[str] = None
    address: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    status: PointStatusEnum
    working_hours: Optional[Dict[str, Any]] = None
    accepts_online_orders: bool
    accepts_scheduled_orders: bool

    class Config:
        from_attributes = True


class PointWithCashiers(Point):
    """Point with cashiers included"""
    cashiers: List["CashierInDB"] = []

    class Config:
        from_attributes = True


class PointQRCode(BaseModel):
    point_id: int
    qr_code_url: str
    deep_link: str


class PointSearchFilters(BaseModel):
    query: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_km: Optional[float] = Field(None, ge=0.1, le=100)
    status: Optional[PointStatusEnum] = None
    accepts_online_orders: Optional[bool] = None
    accepts_scheduled_orders: Optional[bool] = None


# Forward reference resolution
from app.schemas.cashier import CashierInDB
PointWithCashiers.model_rebuild()