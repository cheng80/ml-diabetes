# 요청/응답 스키마 (한글 alias 지원)
from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field


class PredictRequest(BaseModel):
    """예측 입력 (모두 선택, 한글 키 가능)"""
    pregnancies: float | None = Field(None, alias="임신횟수")
    glucose: float | None = Field(None, alias="혈당")
    blood_pressure: float | None = Field(None, alias="혈압")
    skin_thickness: float | None = Field(None, alias="피부두께")
    insulin: float | None = Field(None, alias="인슐린")
    bmi: float | None = Field(None, alias="BMI")
    pedigree: float | None = Field(None, alias="가족력지표")
    age: float | None = Field(None, alias="나이")

    model_config = ConfigDict(populate_by_name=True)


class PredictResponse(BaseModel):
    """예측 결과"""
    prediction: int
    probability: float
    label: str
    input: dict[str, float]
    chart_image_base64: str | None = None


class GeocodeRequest(BaseModel):
    """주소 입력"""
    address: str = Field(..., description="변환할 주소")


class GeocodeResponse(BaseModel):
    """lat/lng 반환"""
    lat: str
    lng: str
