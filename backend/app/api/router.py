from fastapi import APIRouter

from app.api.auth import router as auth_router

api_router = APIRouter()

# Include all routers
api_router.include_router(auth_router)

# Health check endpoint
@api_router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "queue-management-api"}