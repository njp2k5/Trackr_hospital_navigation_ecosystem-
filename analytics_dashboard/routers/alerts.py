"""Alert-related endpoints for Hospital Analytics Dashboard."""

from fastapi import APIRouter

from models import AlertsResponse
from data import get_alerts_data

router = APIRouter(tags=["Alerts"])


@router.get("/alerts", response_model=AlertsResponse)
async def get_alerts() -> AlertsResponse:
    """
    Get active hospital alerts.
    
    Returns all current alerts with their severity level (critical,
    warning, info), message, and timestamp.
    """
    alerts = get_alerts_data()
    return AlertsResponse(alerts=alerts)
