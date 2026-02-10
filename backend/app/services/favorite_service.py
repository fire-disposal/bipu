"""收藏服务"""
from sqlalchemy.orm import Session, joinedload
from typing import List, Tuple, Optional
from app.models.favorite import Favorite
from app.models.message import Message
from app.models.user import User

class FavoriteService:
    
    @staticmethod
    def add_favorite(db: Session, user: User, message_id: int, note: Optional[str] = None) -> Favorite:
        """添加收藏"""
        # 验证消息是否存在
        message = db.query(Message).filter(Message.id == message_id).first()
        if not message:
            raise ValueError("Message not found")
            
        # 检查是否已收藏
        existing = db.query(Favorite).filter(
            Favorite.user_id == user.id,
            Favorite.message_id == message_id
        ).first()
        
        if existing:
            # 如果已存在，更新备注
            if note is not None:
                existing.note = note
                db.commit()
                db.refresh(existing)
            return existing
            
        # 创建新收藏
        new_favorite = Favorite(
            user_id=user.id,
            message_id=message_id,
            note=note
        )
        db.add(new_favorite)
        db.commit()
        db.refresh(new_favorite)
        return new_favorite

    @staticmethod
    def remove_favorite(db: Session, user: User, message_id: int) -> bool:
        """取消收藏"""
        favorite = db.query(Favorite).filter(
            Favorite.user_id == user.id,
            Favorite.message_id == message_id
        ).first()
        
        if not favorite:
            return False
            
        db.delete(favorite)
        db.commit()
        return True

    @staticmethod
    def get_favorites(
        db: Session, 
        user: User, 
        page: int = 1, 
        page_size: int = 20
    ) -> Tuple[List[Favorite], int]:
        """获取收藏列表"""
        query = db.query(Favorite).options(joinedload(Favorite.message)).filter(
            Favorite.user_id == user.id
        ).order_by(Favorite.created_at.desc())
        
        total = query.count()
        favorites = query.offset((page - 1) * page_size).limit(page_size).all()
        
        return favorites, total
