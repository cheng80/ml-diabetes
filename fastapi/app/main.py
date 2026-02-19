# 당뇨 예측 API 서버 (schemas, model_loader, predictor, geocoding)
from __future__ import annotations

import socket
from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.geocoding import geocoding
from app.model_loader import MODEL_METADATA
from app.predictor import predict_with_model
from app.schemas import GeocodeRequest, GeocodeResponse, PredictRequest, PredictResponse

app = FastAPI(title="Diabetes Prediction API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _get_local_ip() -> str:
    """서버 PC의 로컬 네트워크 IP (실기기 연결용)"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


@app.get("/health")
def health() -> dict[str, Any]:
    """서버 상태 + 모델 정보 + local_ip (실기기용 URL 제안)"""
    local_ip = _get_local_ip()
    return {
        "status": "ok",
        "algorithm": MODEL_METADATA.get("algorithm"),
        "accuracy": MODEL_METADATA.get("accuracy"),
        "auc_roc": MODEL_METADATA.get("auc_roc"),
        "f1_score": MODEL_METADATA.get("f1_score"),
        "local_ip": local_ip,
        "suggested_url": f"http://{local_ip}:8000",
    }


@app.post("/predict", response_model=PredictResponse)
def predict(payload: PredictRequest) -> PredictResponse:
    """ML 예측"""
    return predict_with_model(payload)


@app.post("/predict/dummy", response_model=PredictResponse)
def predict_dummy(payload: PredictRequest) -> PredictResponse:
    """UI 테스트용 (라벨에 "(더미)" 붙음)"""
    return predict_with_model(payload, suffix="(더미)")


@app.post("/geocode", response_model=GeocodeResponse)
def geocode_address(payload: GeocodeRequest) -> GeocodeResponse:
    """주소 → lat/lng"""
    result = geocoding(payload.address)
    if result is None:
        raise HTTPException(status_code=404, detail="주소를 찾을 수 없습니다.")
    return GeocodeResponse(lat=result["lat"], lng=result["lng"])
