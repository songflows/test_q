from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum

from app.core.database import Base


class AuthProviderEnum(enum.Enum):
    EMAIL = "email"
    GOOGLE = "google"
    FACEBOOK = "facebook"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255), nullable=True)
    hashed_password = Column(String(255), nullable=True)  # Nullable for OAuth users
    
    # OAuth fields
    auth_provider = Column(Enum(AuthProviderEnum), default=AuthProviderEnum.EMAIL)
    oauth_id = Column(String(255), nullable=True)  # ID from OAuth provider
    
    # Profile info
    phone = Column(String(20), nullable=True)
    avatar_url = Column(Text, nullable=True)
    
    # Account status
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    owned_points = relationship("Point", back_populates="owner")
    cashier_assignments = relationship("Cashier", back_populates="assigned_user")
    orders = relationship("Order", back_populates="user")

    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}', provider='{self.auth_provider.value}')>"