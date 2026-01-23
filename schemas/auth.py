from pydantic import BaseModel

class HospitalUserCreate(BaseModel):
    username: str
    password: str

class HospitalAuthToken(BaseModel):
    access_token: str
    token_type: str
    email: str
