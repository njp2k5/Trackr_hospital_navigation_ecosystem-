"""Ward-related endpoints for Hospital Analytics Dashboard."""

from fastapi import APIRouter, HTTPException

from models import WardsStatusResponse, WardStaffResponse
from data import get_all_wards, get_staff_by_ward_id

router = APIRouter(prefix="/wards", tags=["Wards"])


@router.get("/status", response_model=WardsStatusResponse)
async def get_wards_status() -> WardsStatusResponse:
    """
    Get current OP and bed status for all wards.
    
    Returns the current operational number and bed occupancy
    information for every ward in the hospital.
    """
    wards = get_all_wards()
    return WardsStatusResponse(wards=wards)


@router.get("/{ward_id}/staff", response_model=WardStaffResponse)
async def get_ward_staff(ward_id: str) -> WardStaffResponse:
    """
    Get staff shift information for a specific ward.
    
    Returns doctors on duty, absent doctors with their substitutes,
    and the count of nurses currently on duty.
    
    Args:
        ward_id: The unique identifier of the ward (e.g., "ER", "ICU")
    """
    staff = get_staff_by_ward_id(ward_id)
    
    if staff is None:
        raise HTTPException(
            status_code=404,
            detail=f"Ward '{ward_id}' not found. Available wards: ER, ICU, GENERAL, PEDIATRIC, MATERNITY, SURGERY, CARDIOLOGY"
        )
    
    return staff
