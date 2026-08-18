from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class CredentialsRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=12, max_length=128)


class UserResponse(BaseModel):
    id: str
    email: EmailStr
    email_verified: bool = False


class AuthenticationResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    refresh_token: str
    refresh_expires_in: int
    user: UserResponse


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(min_length=32, max_length=512)


class EmailActionRequest(BaseModel):
    email: EmailStr


class ActionTokenRequest(BaseModel):
    token: str = Field(min_length=32, max_length=512)


class PasswordResetRequest(ActionTokenRequest):
    new_password: str = Field(min_length=12, max_length=128)


class MessageResponse(BaseModel):
    message: str


class SessionResponse(BaseModel):
    id: str
    is_current: bool
    created_at: datetime
    expires_at: datetime
