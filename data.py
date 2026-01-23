"""Mock/simulated data for Hospital Analytics Dashboard."""

from datetime import datetime, timedelta
from models import (
    WardStatus,
    WardStaffResponse,
    DoctorsInfo,
    AbsentDoctor,
    MaintenanceActivity,
    Alert,
)


# -------------------- Ward Data --------------------

WARDS_DATA: dict[str, WardStatus] = {
    "ER": WardStatus(
        ward_id="ER",
        current_op_number=42,
        total_beds=50,
        occupied_beds=52,  # Over capacity for demo
    ),
    "ICU": WardStatus(
        ward_id="ICU",
        current_op_number=15,
        total_beds=20,
        occupied_beds=18,
    ),
    "GENERAL": WardStatus(
        ward_id="GENERAL",
        current_op_number=78,
        total_beds=100,
        occupied_beds=72,
    ),
    "PEDIATRIC": WardStatus(
        ward_id="PEDIATRIC",
        current_op_number=23,
        total_beds=30,
        occupied_beds=21,
    ),
    "MATERNITY": WardStatus(
        ward_id="MATERNITY",
        current_op_number=12,
        total_beds=25,
        occupied_beds=19,
    ),
    "SURGERY": WardStatus(
        ward_id="SURGERY",
        current_op_number=8,
        total_beds=15,
        occupied_beds=14,
    ),
    "CARDIOLOGY": WardStatus(
        ward_id="CARDIOLOGY",
        current_op_number=31,
        total_beds=35,
        occupied_beds=28,
    ),
}


# -------------------- Staff Data --------------------

STAFF_DATA: dict[str, WardStaffResponse] = {
    "ER": WardStaffResponse(
        ward_id="ER",
        doctors=DoctorsInfo(
            on_duty=["Dr. Patel", "Dr. Kumar", "Dr. Singh"],
            absent=[
                AbsentDoctor(name="Dr. Gupta", substitute="Dr. Reddy"),
            ],
        ),
        nurses_on_duty=15,
    ),
    "ICU": WardStaffResponse(
        ward_id="ICU",
        doctors=DoctorsInfo(
            on_duty=["Dr. Rao", "Dr. Mehta"],
            absent=[
                AbsentDoctor(name="Dr. Sharma", substitute="Dr. Verma"),
            ],
        ),
        nurses_on_duty=12,
    ),
    "GENERAL": WardStaffResponse(
        ward_id="GENERAL",
        doctors=DoctorsInfo(
            on_duty=["Dr. Agarwal", "Dr. Joshi", "Dr. Nair", "Dr. Iyer"],
            absent=[],
        ),
        nurses_on_duty=20,
    ),
    "PEDIATRIC": WardStaffResponse(
        ward_id="PEDIATRIC",
        doctors=DoctorsInfo(
            on_duty=["Dr. Kapoor", "Dr. Mishra"],
            absent=[
                AbsentDoctor(name="Dr. Chatterjee", substitute="Dr. Banerjee"),
            ],
        ),
        nurses_on_duty=10,
    ),
    "MATERNITY": WardStaffResponse(
        ward_id="MATERNITY",
        doctors=DoctorsInfo(
            on_duty=["Dr. Desai", "Dr. Shah"],
            absent=[],
        ),
        nurses_on_duty=14,
    ),
    "SURGERY": WardStaffResponse(
        ward_id="SURGERY",
        doctors=DoctorsInfo(
            on_duty=["Dr. Pillai", "Dr. Menon", "Dr. Nambiar"],
            absent=[
                AbsentDoctor(name="Dr. Krishnan", substitute="Dr. Rajan"),
            ],
        ),
        nurses_on_duty=8,
    ),
    "CARDIOLOGY": WardStaffResponse(
        ward_id="CARDIOLOGY",
        doctors=DoctorsInfo(
            on_duty=["Dr. Bose", "Dr. Sen"],
            absent=[],
        ),
        nurses_on_duty=11,
    ),
}


# -------------------- Maintenance Data --------------------

def get_maintenance_data() -> list[MaintenanceActivity]:
    """Get current maintenance activities with dynamic timestamps."""
    now = datetime.now()
    return [
        MaintenanceActivity(
            type="lift",
            location="Block B",
            status="in_progress",
            expected_completion=now + timedelta(hours=2),
        ),
        MaintenanceActivity(
            type="cleaning",
            location="Ward 3",
            status="in_progress",
            expected_completion=None,
        ),
        MaintenanceActivity(
            type="hvac",
            location="ICU Floor",
            status="scheduled",
            expected_completion=now + timedelta(hours=5),
        ),
        MaintenanceActivity(
            type="electrical",
            location="Pharmacy Wing",
            status="in_progress",
            expected_completion=now + timedelta(hours=1),
        ),
    ]


# -------------------- Alerts Data --------------------

def get_alerts_data() -> list[Alert]:
    """Get current hospital alerts with dynamic timestamps."""
    now = datetime.now()
    return [
        Alert(
            level="critical",
            message="Pharmacy is currently closed",
            timestamp=now - timedelta(minutes=45),
        ),
        Alert(
            level="warning",
            message="ER waiting time exceeds threshold",
            timestamp=now - timedelta(minutes=15),
        ),
        Alert(
            level="warning",
            message="Blood bank O- stock running low",
            timestamp=now - timedelta(hours=1),
        ),
        Alert(
            level="info",
            message="Scheduled power maintenance in Block C at 23:00",
            timestamp=now - timedelta(hours=2),
        ),
    ]


# -------------------- Helper Functions --------------------

def get_all_wards() -> list[WardStatus]:
    """Get status of all wards."""
    return list(WARDS_DATA.values())


def get_ward_by_id(ward_id: str) -> WardStatus | None:
    """Get status of a specific ward."""
    return WARDS_DATA.get(ward_id.upper())


def get_staff_by_ward_id(ward_id: str) -> WardStaffResponse | None:
    """Get staff information for a specific ward."""
    return STAFF_DATA.get(ward_id.upper())


def get_wards_over_capacity() -> list[str]:
    """Get list of ward IDs that are over capacity."""
    return [
        ward.ward_id
        for ward in WARDS_DATA.values()
        if ward.occupied_beds > ward.total_beds
    ]
