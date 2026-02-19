# joblib 모델 로드 + 피처 범위/라벨/기본값
from __future__ import annotations

from pathlib import Path
from typing import Any

import joblib

APP_DIR = Path(__file__).resolve().parent
MODEL_PATH = APP_DIR / "diabetes_model.h5"
if not MODEL_PATH.exists():
    raise FileNotFoundError(
        f"모델 파일을 찾을 수 없습니다: {MODEL_PATH}\n"
        "먼저 python train_model.py 를 실행하세요."
    )

_bundle = joblib.load(MODEL_PATH)

MODEL = _bundle["model"]
FEATURE_NAMES: list[str] = _bundle["feature_names"]
ORIG_MEANS: dict[str, float] = _bundle["orig_means"]
ORIG_STDS: dict[str, float] = _bundle["orig_stds"]
MODEL_METADATA: dict[str, Any] = _bundle["metadata"]

print(f"[모델 로드 완료] {MODEL_METADATA.get('algorithm')}, "
      f"정확도={MODEL_METADATA.get('accuracy')}, "
      f"데이터={MODEL_METADATA.get('data_source')}")

# 피처 허용 범위 (프론트와 동일)
FEATURE_RANGES: dict[str, tuple[float, float]] = {
    "pregnancies": (0.0, 17.0),
    "glucose": (0.0, 199.0),
    "blood_pressure": (0.0, 122.0),
    "skin_thickness": (0.0, 99.0),
    "insulin": (0.0, 846.0),
    "bmi": (0.0, 67.1),
    "pedigree": (0.078, 2.42),
    "age": (21.0, 81.0),
}

# 차트용 한글 라벨
FEATURE_LABELS: dict[str, str] = {
    "pregnancies": "임신횟수",
    "glucose": "혈당",
    "blood_pressure": "혈압",
    "skin_thickness": "피부두께",
    "insulin": "인슐린",
    "bmi": "BMI",
    "pedigree": "가족력지표",
    "age": "나이",
}

# 미입력 시 기본값
FEATURE_DEFAULTS: dict[str, float] = {
    "pregnancies": 0.0,
    "glucose": 117.0,
    "blood_pressure": 72.0,
    "skin_thickness": 29.0,
    "insulin": 125.0,
    "bmi": 32.3,
    "pedigree": 0.3725,
    "age": 29.0,
}
