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

# Base OP numbers for each ward (used for dynamic calculation)
WARD_BASE_OP: dict[str, int] = {
    "ER": 42,
    "CASUALTY": 15,
    "GENERAL": 78,
    "PEDIATRIC": 23,
    "MATERNITY": 12,
    "SURGERY": 8,
    "CARDIOLOGY": 31,
}

# Static ward data (beds info)
WARDS_STATIC: dict[str, dict] = {
    "ER": {"total_beds": 50, "occupied_beds": 52},  # Over capacity for demo
    "CASUALTY": {"total_beds": 20, "occupied_beds": 18},
    "GENERAL": {"total_beds": 100, "occupied_beds": 72},
    "PEDIATRIC": {"total_beds": 30, "occupied_beds": 21},
    "MATERNITY": {"total_beds": 25, "occupied_beds": 19},
    "SURGERY": {"total_beds": 15, "occupied_beds": 14},
    "CARDIOLOGY": {"total_beds": 35, "occupied_beds": 28},
}


def get_dynamic_op_number(ward_id: str) -> int:
    """
    Returns a dynamic OP number for the ward, changing every minute,
    out of sync for each ward using ward-specific offset.
    
    When the total OP exceeds 99, it rolls back to 1 and continues incrementing.
    """
    base = WARD_BASE_OP.get(ward_id, 0)
    now = datetime.now()
    # Each ward gets a different offset based on its name hash
    offset = hash(ward_id) % 7
    minute = now.minute
    # OP number changes every minute, different phase per ward
    raw_op = base + ((minute + offset) % 10)
    # Rollback logic: when OP exceeds 99, roll back to 1 and continue
    if raw_op > 99:
        return ((raw_op - 1) % 99) + 1
    return raw_op


WARDS_DATA: dict[str, WardStatus] = {
    "ER": WardStatus(
        ward_id="ER",
        current_op_number=42,
        total_beds=50,
        occupied_beds=52,  # Over capacity for demo
    ),
    "CASUALTY": WardStatus(
        ward_id="CASUALTY",
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
    "CASUALTY": WardStaffResponse(
        ward_id="CASUALTY",
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
            location="CASUALTY Floor",
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
    """Get status of all wards with dynamic OP numbers."""
    return [
        WardStatus(
            ward_id=ward_id,
            current_op_number=get_dynamic_op_number(ward_id),
            total_beds=WARDS_STATIC[ward_id]["total_beds"],
            occupied_beds=WARDS_STATIC[ward_id]["occupied_beds"],
        )
        for ward_id in WARDS_STATIC
    ]


def get_ward_by_id(ward_id: str) -> WardStatus | None:
    """Get status of a specific ward with dynamic OP number."""
    ward_id = ward_id.upper()
    if ward_id not in WARDS_STATIC:
        return None
    return WardStatus(
        ward_id=ward_id,
        current_op_number=get_dynamic_op_number(ward_id),
        total_beds=WARDS_STATIC[ward_id]["total_beds"],
        occupied_beds=WARDS_STATIC[ward_id]["occupied_beds"],
    )


def get_staff_by_ward_id(ward_id: str) -> WardStaffResponse | None:
    """Get staff information for a specific ward."""
    return STAFF_DATA.get(ward_id.upper())


def get_wards_over_capacity() -> list[str]:
    """Get list of ward IDs that are over capacity."""
    return [
        ward_id
        for ward_id, data in WARDS_STATIC.items()
        if data["occupied_beds"] > data["total_beds"]
    ]
