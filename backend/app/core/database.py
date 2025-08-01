from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
import redis.asyncio as redis

from app.core.config import settings


# Database engine
engine = create_async_engine(
    settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://"),
    echo=settings.DEBUG,
    pool_pre_ping=True,
)

# Session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# Redis connection
redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)


class Base(DeclarativeBase):
    pass


async def get_db():
    """Dependency to get database session"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def get_redis():
    """Dependency to get Redis client"""
    return redis_client


async def create_tables():
    """Create all tables"""
    from app.models import user, point, cashier, order  # Import all models
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)