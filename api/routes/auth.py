from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from db.session import SessionLocal
from models.user import HospitalUser
from schemas.auth import HospitalUserCreate, HospitalAuthToken
from auth.security import hash_password, verify_password
from auth.oauth2 import oauth2_scheme
from auth.jwt_handler import create_access_token, decode_access_token

router = APIRouter(prefix="/auth", tags=["Hospital Authentication"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/signup")
def signup(user: HospitalUserCreate, db: Session = Depends(get_db)):
    try:
        existing_user = db.query(HospitalUser).filter(HospitalUser.username == user.username).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="User already exists")

        hashed_pwd = hash_password(user.password)
        
        new_user = HospitalUser(
            username=user.username,
            hashed_password=hashed_pwd
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        return {"message": "Hospital user created successfully"}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.post("/token", response_model=HospitalAuthToken)
def login(
    form: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    try:
        user = db.query(HospitalUser).filter(HospitalUser.username == form.username).first()

        if not user or not verify_password(form.password, str(user.hashed_password)):
            raise HTTPException(status_code=401, detail="Invalid credentials")

        token = create_access_token({"sub": user.username})
        return {
            "access_token": token,
            "token_type": "bearer",
            "email": user.username
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/me")
def get_current_hospital_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """Protected endpoint to get current hospital user info - demonstrates OAuth2 in Swagger UI"""
    
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    username = payload.get("sub")
    if not username:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    user = db.query(HospitalUser).filter(HospitalUser.username == username).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "username": user.username,
        "email": user.username
    }
