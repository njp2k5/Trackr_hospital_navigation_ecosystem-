"""Main FastAPI application for Hospital Analytics Dashboard."""

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import (
    wards_router,
    maintenance_router,
    alerts_router,
    realtime_router,
)

# Create FastAPI application
app = FastAPI(
    title="Hospital Analytics Dashboard API",
    description="Real-time hospital analytics API for monitoring wards, staff, maintenance, and alerts.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configure CORS for dashboard frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(wards_router)
app.include_router(maintenance_router)
app.include_router(alerts_router)
app.include_router(realtime_router)


@app.get("/", tags=["Health"])
async def root():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "Hospital Analytics Dashboard API",
        "version": "1.0.0",
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """Detailed health check endpoint."""
    return {
        "status": "healthy",
        "components": {
            "api": "operational",
            "data": "operational",
        },
    }


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )
