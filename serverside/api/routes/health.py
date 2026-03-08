from fastapi import APIRouter

router = APIRouter(prefix="/health", tags=["Hospital System Health"])

@router.get("/")
def hospital_system_health():
    return {"status": "ok", "service": "Hospital Navigation System"}
