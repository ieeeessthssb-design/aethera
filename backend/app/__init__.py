"""Import all models so Alembic autodiscovery works."""
from app.models.user import User
from app.models.farm import Farm
from app.models.device import Device
from app.models.reading import Reading
from app.models.advice_log import AdviceLog
from app.models.expert_case import ExpertCase, ExpertReview

__all__ = ["User", "Farm", "Device", "Reading", "AdviceLog", "ExpertCase", "ExpertReview"]
