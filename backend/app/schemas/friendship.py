from pydantic import BaseModel, Field
from datetime import datetime
from enum import Enum
from typing import Optional

class FriendshipStatus(str, Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    BLOCKED = "blocked"

class FriendshipBase(BaseModel):
    user_id: int
    friend_id: int
    status: FriendshipStatus = FriendshipStatus.PENDING

class FriendshipCreate(FriendshipBase):
    pass

class FriendshipUpdate(BaseModel):
    status: Optional[FriendshipStatus] = None

class FriendshipResponse(FriendshipBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class FriendshipList(BaseModel):
    items: list[FriendshipResponse]
    total: int
    page: int
    size: int