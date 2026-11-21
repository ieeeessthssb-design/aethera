"""Speech-to-text interface. Stub now, Whisper (Derja fine-tune) later."""
from abc import ABC, abstractmethod
from typing import Optional

from app.core.config import settings


class STTInterface(ABC):
    @abstractmethod
    async def transcribe(self, audio: bytes, content_type: Optional[str] = None) -> str: ...


class StubSTTService(STTInterface):
    """Returns a fixed Derja-style transcript so the voice flow is demoable."""

    async def transcribe(self, audio: bytes, content_type: Optional[str] = None) -> str:
        return "الطماطم متاعي ورقها يتصفر، شنوة نعمل؟"


def get_stt_service() -> STTInterface:
    # Plug a Whisper implementation here when settings.stt_provider == "whisper".
    return StubSTTService()
