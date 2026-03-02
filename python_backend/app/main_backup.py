from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session
from decouple import config

from .database import engine, get_db
from .models import Base
from .routers import auth, users, hospitals, services, appointments, messages, payments, admin
from .auth import get_current_user

# Configuration
PROJECT_NAME = config("PROJECT_NAME", default="Fertility Services API")
VERSION = config("VERSION", default="1.0.0")
API_V1_STR = config("API_V1_STR", default="/api/v1")
BACKEND_CORS_ORIGINS = config("BACKEND_CORS_ORIGINS", default="").split(",")

# Create database tables
Base.metadata.create_all(bind=engine)

# Initialize FastAPI app
app = FastAPI(
    title=PROJECT_NAME,
    version=VERSION,
    description="A comprehensive fertility services platform API",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=BACKEND_CORS_ORIGINS or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()

# Health check endpoint
@app.get("/")
async def root():
    return {
        "message": "Fertility Services API",
        "version": VERSION,
        "status": "healthy"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": "2024-01-01T00:00:00Z"}

# Include routers
app.include_router(auth.router, prefix=f"{API_V1_STR}/auth", tags=["Authentication"])
app.include_router(users.router, prefix=f"{API_V1_STR}/users", tags=["Users"])
app.include_router(hospitals.router, prefix=f"{API_V1_STR}/hospitals", tags=["Hospitals"])
app.include_router(services.router, prefix=f"{API_V1_STR}/services", tags=["Services"])
app.include_router(appointments.router, prefix=f"{API_V1_STR}/appointments", tags=["Appointments"])
app.include_router(messages.router, prefix=f"{API_V1_STR}/messages", tags=["Messages"])
app.include_router(payments.router, prefix=f"{API_V1_STR}/payments", tags=["Payments"])
app.include_router(admin.router, prefix=f"{API_V1_STR}/admin", tags=["Admin"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=config("DEBUG", default=False, cast=bool)
    )
