from enum import Enum


class MessageType(str, Enum):
    NORMAL = "NORMAL"
    VOICE = "VOICE"
    SYSTEM = "SYSTEM"
