# 주소 → lat/lng 반환 (Nominatim, 가입 불필요)
from __future__ import annotations

from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderServiceError


def geocoding(address: str) -> dict[str, str] | None:
    """주소 → {"lat":, "lng":} 또는 None"""
    if not address or not address.strip():
        return None

    addr = address.strip()
    geolocator = Nominatim(user_agent="diabetes_app_kr", timeout=10)

    # 1차: 원본 주소
    geo = _try_geocode(geolocator, addr)
    if geo is not None:
        return {"lat": str(geo.latitude), "lng": str(geo.longitude)}

    # 2차: ", 대한민국" 붙여서 재시도
    if "대한민국" not in addr and "South Korea" not in addr and "Korea" not in addr:
        geo = _try_geocode(geolocator, f"{addr}, 대한민국")
        if geo is not None:
            return {"lat": str(geo.latitude), "lng": str(geo.longitude)}

    return None


def _try_geocode(geolocator: Nominatim, query: str):
    """타임아웃/에러 시 None"""
    try:
        return geolocator.geocode(query)
    except (GeocoderTimedOut, GeocoderServiceError, AttributeError):
        return None
