from typing import Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import httpx

from app.models.user import User, AuthProviderEnum
from app.schemas.user import UserCreate, UserLogin, OAuthLoginRequest
from app.core.security import (
    verify_password, 
    get_password_hash, 
    create_access_token,
    verify_token
)
from app.core.database import get_db
from app.core.config import settings


security = HTTPBearer()


class AuthService:
    
    @staticmethod
    async def authenticate_user(db: AsyncSession, email: str, password: str) -> Optional[User]:
        """Authenticate user with email and password"""
        result = await db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        
        if not user:
            return None
        
        if user.auth_provider != AuthProviderEnum.EMAIL:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"This account uses {user.auth_provider.value} authentication"
            )
        
        if not user.hashed_password or not verify_password(password, user.hashed_password):
            return None
        
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Inactive user"
            )
        
        return user
    
    @staticmethod
    async def create_user(db: AsyncSession, user_data: UserCreate) -> User:
        """Create new user"""
        # Check if user already exists
        result = await db.execute(select(User).where(User.email == user_data.email))
        if result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        # Hash password if provided
        hashed_password = None
        if user_data.password:
            hashed_password = get_password_hash(user_data.password)
        
        # Create user
        db_user = User(
            email=user_data.email,
            full_name=user_data.full_name,
            phone=user_data.phone,
            avatar_url=user_data.avatar_url,
            hashed_password=hashed_password,
            auth_provider=user_data.auth_provider,
            oauth_id=user_data.oauth_id,
        )
        
        db.add(db_user)
        await db.commit()
        await db.refresh(db_user)
        
        return db_user
    
    @staticmethod
    async def oauth_login(db: AsyncSession, oauth_data: OAuthLoginRequest) -> User:
        """Login or register user via OAuth"""
        user_info = None
        
        if oauth_data.provider == AuthProviderEnum.GOOGLE:
            user_info = await AuthService._verify_google_token(oauth_data.access_token)
        elif oauth_data.provider == AuthProviderEnum.FACEBOOK:
            user_info = await AuthService._verify_facebook_token(oauth_data.access_token)
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unsupported OAuth provider"
            )
        
        if not user_info:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid OAuth token"
            )
        
        # Check if user exists
        result = await db.execute(
            select(User).where(
                User.email == user_info["email"],
                User.auth_provider == oauth_data.provider
            )
        )
        user = result.scalar_one_or_none()
        
        if user:
            # Update user info if needed
            user.full_name = user_info.get("name", user.full_name)
            user.avatar_url = user_info.get("picture", user.avatar_url)
            await db.commit()
            await db.refresh(user)
            return user
        
        # Create new user
        user_create = UserCreate(
            email=user_info["email"],
            full_name=user_info.get("name"),
            avatar_url=user_info.get("picture"),
            auth_provider=oauth_data.provider,
            oauth_id=user_info["id"],
        )
        
        return await AuthService.create_user(db, user_create)
    
    @staticmethod
    async def _verify_google_token(access_token: str) -> Optional[Dict[str, Any]]:
        """Verify Google OAuth token"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    "https://www.googleapis.com/oauth2/v2/userinfo",
                    headers={"Authorization": f"Bearer {access_token}"}
                )
                
                if response.status_code == 200:
                    return response.json()
                return None
        except Exception:
            return None
    
    @staticmethod
    async def _verify_facebook_token(access_token: str) -> Optional[Dict[str, Any]]:
        """Verify Facebook OAuth token"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    "https://graph.facebook.com/me",
                    params={
                        "access_token": access_token,
                        "fields": "id,name,email,picture"
                    }
                )
                
                if response.status_code == 200:
                    return response.json()
                return None
        except Exception:
            return None
    
    @staticmethod
    async def get_current_user(
        credentials: HTTPAuthorizationCredentials = Depends(security),
        db: AsyncSession = Depends(get_db)
    ) -> User:
        """Get current authenticated user"""
        try:
            payload = verify_token(credentials.credentials)
            email: str = payload.get("sub")
            
            if email is None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Could not validate credentials"
                )
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials"
            )
        
        result = await db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Inactive user"
            )
        
        return user
    
    @staticmethod
    async def get_current_active_user(
        current_user: User = Depends(get_current_user),
    ) -> User:
        """Get current active user (alias for better readability)"""
        return current_user