from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List
from app.schemas.message_new import MessageResponse

class FavoriteCreate(BaseModel):
    note: Optional[str] = None

class FavoriteResponse(BaseModel):
    id: int
    message_id: int
    user_id: int
    note: Optional[str]
    created_at: datetime
    message: Optional[MessageResponse] = None # 包含完整消息详情
    
    class Config:
        from_attributes = True

class FavoriteListResponse(BaseModel):
    favorites: List[FavoriteResponse]
    total: int
    page: int
    page_size: int
