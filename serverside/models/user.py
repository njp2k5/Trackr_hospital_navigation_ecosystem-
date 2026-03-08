from sqlalchemy import Column, Integer, String
from db.base import Base

class HospitalUser(Base):
    __tablename__ = "hospital_users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
