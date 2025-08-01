from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import create_access_token
from app.core.config import settings
from app.schemas.user import (
    UserRegister, 
    UserLogin, 
    Token, 
    User,
    UserProfile,
    OAuthLoginRequest
)
from app.services.auth import AuthService


router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/register", response_model=Token)
async def register(
    user_data: UserRegister,
    db: AsyncSession = Depends(get_db)
):
    """Register new user with email and password"""
    from app.schemas.user import UserCreate
    from app.models.user import AuthProviderEnum
    
    user_create = UserCreate(
        email=user_data.email,
        full_name=user_data.full_name,
        phone=user_data.phone,
        password=user_data.password,
        auth_provider=AuthProviderEnum.EMAIL
    )
    
    user = await AuthService.create_user(db, user_create)
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=User.from_orm(user)
    )


@router.post("/login", response_model=Token)
async def login(
    user_data: UserLogin,
    db: AsyncSession = Depends(get_db)
):
    """Login with email and password"""
    user = await AuthService.authenticate_user(db, user_data.email, user_data.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=User.from_orm(user)
    )


@router.post("/login/oauth", response_model=Token)
async def oauth_login(
    oauth_data: OAuthLoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """Login with OAuth (Google, Facebook)"""
    user = await AuthService.oauth_login(db, oauth_data)
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=User.from_orm(user)
    )


@router.post("/token", response_model=Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    """OAuth2 compatible token endpoint"""
    user = await AuthService.authenticate_user(db, form_data.username, form_data.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user=User.from_orm(user)
    )


@router.get("/me", response_model=UserProfile)
async def get_current_user_profile(
    current_user: User = Depends(AuthService.get_current_user)
):
    """Get current user profile"""
    return UserProfile.from_orm(current_user)


@router.get("/verify")
async def verify_token(
    current_user: User = Depends(AuthService.get_current_user)
):
    """Verify current token"""
    return {"valid": True, "user_id": current_user.id, "email": current_user.email}