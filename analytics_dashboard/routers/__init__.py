"""Router package for Hospital Analytics Dashboard."""

from routers.wards import router as wards_router
from routers.maintenance import router as maintenance_router
from routers.alerts import router as alerts_router
from routers.realtime import router as realtime_router

__all__ = [
    "wards_router",
    "maintenance_router",
    "alerts_router",
    "realtime_router",
]
