"""Realtime summary endpoints for Hospital Analytics Dashboard."""

from fastapi import APIRouter

from models import RealtimeSummaryResponse
from data import get_alerts_data, get_maintenance_data, get_wards_over_capacity

router = APIRouter(prefix="/realtime", tags=["Realtime"])


@router.get("/summary", response_model=RealtimeSummaryResponse)
async def get_realtime_summary() -> RealtimeSummaryResponse:
    """
    Get aggregated snapshot for dashboard displays.
    
    Returns a summary including:
    - Total count of active alerts
    - List of wards currently over capacity
    - Count of ongoing maintenance activities
    """
    alerts = get_alerts_data()
    maintenance = get_maintenance_data()
    wards_over_capacity = get_wards_over_capacity()
    
    return RealtimeSummaryResponse(
        total_active_alerts=len(alerts),
        wards_over_capacity=wards_over_capacity,
        maintenance_count=len(maintenance),
    )
