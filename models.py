"""Pydantic models for Hospital Analytics Dashboard."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel


# -------------------- Ward Models --------------------

class WardStatus(BaseModel):
    """Current status of a hospital ward."""
    ward_id: str
    current_op_number: int
    total_beds: int
    occupied_beds: int


class WardsStatusResponse(BaseModel):
    """Response model for all wards status."""
    wards: list[WardStatus]


# -------------------- Staff Models --------------------

class AbsentDoctor(BaseModel):
    """Information about an absent doctor and their substitute."""
    name: str
    substitute: str


class DoctorsInfo(BaseModel):
    """Doctor shift information."""
    on_duty: list[str]
    absent: list[AbsentDoctor]


class WardStaffResponse(BaseModel):
    """Response model for ward staff information."""
    ward_id: str
    doctors: DoctorsInfo
    nurses_on_duty: int


# -------------------- Maintenance Models --------------------

class MaintenanceActivity(BaseModel):
    """Ongoing maintenance activity in the hospital."""
    type: str
    location: str
    status: str
    expected_completion: Optional[datetime] = None


class MaintenanceResponse(BaseModel):
    """Response model for maintenance activities."""
    maintenance: list[MaintenanceActivity]


# -------------------- Alert Models --------------------

class Alert(BaseModel):
    """Active hospital alert."""
    level: str  # "critical", "warning", "info"
    message: str
    timestamp: Optional[datetime] = None


class AlertsResponse(BaseModel):
    """Response model for hospital alerts."""
    alerts: list[Alert]


# -------------------- Realtime Summary Models --------------------

class RealtimeSummaryResponse(BaseModel):
    """Aggregated snapshot for dashboard."""
    total_active_alerts: int
    wards_over_capacity: list[str]
    maintenance_count: int
