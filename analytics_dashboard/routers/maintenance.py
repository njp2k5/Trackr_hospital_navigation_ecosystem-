"""Maintenance-related endpoints for Hospital Analytics Dashboard."""

from fastapi import APIRouter

from models import MaintenanceResponse
from data import get_maintenance_data

router = APIRouter(tags=["Maintenance"])


@router.get("/maintenance", response_model=MaintenanceResponse)
async def get_maintenance() -> MaintenanceResponse:
    """
    Get ongoing maintenance activities inside the hospital.
    
    Returns all current maintenance activities including their type,
    location, status, and expected completion time (if available).
    """
    maintenance = get_maintenance_data()
    return MaintenanceResponse(maintenance=maintenance)
