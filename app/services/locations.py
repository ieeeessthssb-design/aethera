"""Resolve a farm's coordinates: exact lat/lng if set, else the governorate centroid.

Centroids are approximate (good enough for weather at governorate scale, not for field-level work).
"""
from __future__ import annotations

import unicodedata
from typing import Optional

# (lat, lng): names in French/English spelling and Arabic
_GOVERNORATES = {
    (36.81, 10.18): ("tunis", "تونس"),
    (36.86, 10.19): ("ariana", "أريانة"),
    (36.75, 10.23): ("ben arous", "بن عروس"),
    (36.81, 10.10): ("manouba", "منوبة"),
    (36.45, 10.74): ("nabeul", "نابل"),
    (36.40, 10.14): ("zaghouan", "زغوان"),
    (37.27, 9.87): ("bizerte", "بنزرت"),
    (36.73, 9.18): ("beja", "باجة"),
    (36.50, 8.78): ("jendouba", "جندوبة"),
    (36.17, 8.71): ("le kef", "kef", "الكاف"),
    (36.08, 9.37): ("siliana", "سليانة"),
    (35.83, 10.64): ("sousse", "سوسة"),
    (35.78, 10.83): ("monastir", "المنستير"),
    (35.50, 11.06): ("mahdia", "المهدية"),
    (34.74, 10.76): ("sfax", "صفاقس"),
    (35.68, 10.10): ("kairouan", "القيروان"),
    (35.17, 8.84): ("kasserine", "القصرين"),
    (35.04, 9.49): ("sidi bouzid", "سيدي بوزيد"),
    (33.88, 10.10): ("gabes", "قابس"),
    (33.35, 10.50): ("medenine", "مدنين"),
    (32.93, 10.45): ("tataouine", "تطاوين"),
    (34.43, 8.78): ("gafsa", "قفصة"),
    (33.92, 8.13): ("tozeur", "توزر"),
    (33.70, 8.97): ("kebili", "قبلي"),
}


def _norm(s: str) -> str:
    s = unicodedata.normalize("NFKD", s.strip().lower())
    return "".join(c for c in s if not unicodedata.combining(c)).replace("-", " ").replace("_", " ")


_BY_NAME = {_norm(n): coords for coords, names in _GOVERNORATES.items() for n in names}


def resolve_location(farm) -> Optional[tuple[float, float, str]]:
    """Returns (lat, lng, "farm" | "region") or None when the location is unknown."""
    lat, lng = getattr(farm, "lat", None), getattr(farm, "lng", None)
    if lat is not None and lng is not None:
        return lat, lng, "farm"
    region = getattr(farm, "region", None)
    if region:
        key = _norm(region)
        coords = _BY_NAME.get(key)  # exact match only ("Tunisia" must not resolve to Tunis)
        if coords:
            return coords[0], coords[1], "region"
    return None
