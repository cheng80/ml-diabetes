from __future__ import annotations

from pathlib import Path

import joblib

APP_DIR = Path(__file__).resolve().parent

MODEL_SUGAR_PATH = APP_DIR / "model_sugar.joblib"
if not MODEL_SUGAR_PATH.exists():
    raise FileNotFoundError(f"혈당 포함 모델 파일을 찾을 수 없습니다: {MODEL_SUGAR_PATH}")

MODEL_NO_SUGAR_PATH = APP_DIR / "model_no_sugar.joblib"
if not MODEL_NO_SUGAR_PATH.exists():
    raise FileNotFoundError(f"혈당 미포함 모델 파일을 찾을 수 없습니다: {MODEL_NO_SUGAR_PATH}")

MODEL_SUGAR = joblib.load(MODEL_SUGAR_PATH)
MODEL_NO_SUGAR = joblib.load(MODEL_NO_SUGAR_PATH)

FEATURES_SUGAR = ["glucose", "bmi", "age", "pregnancies"]
FEATURES_NO_SUGAR = ["bmi", "age", "pregnancies"]

ALIAS_TO_ENG = {
    "혈당": "glucose",
    "BMI": "bmi",
    "나이": "age",
    "임신횟수": "pregnancies",
}

FEATURE_LABELS = {
    "glucose": "혈당",
    "bmi": "BMI",
    "age": "나이",
    "pregnancies": "임신횟수",
}

FEATURE_RANGES = {
    "glucose": (44.0, 199.0),
    "bmi": (0.0, 67.1),
    "age": (1.0, 100.0),
    "pregnancies": (0.0, 17.0),
}

# ---------------------------------------------------------------------------
# 전처리: 원본 수치 -> StandardScaler 표준화 (z-score)
# 당뇨.csv 전체 데이터에 IQR Clipping 후 StandardScaler.fit_transform 한 통계값
# ---------------------------------------------------------------------------
SCALER_STATS: dict[str, tuple[float, float]] = {
    "pregnancies": (3.837240, 3.341979),
    "glucose":     (121.686763, 30.515624),
    "bmi":         (32.394716, 6.711356),
    "age":         (33.199870, 11.620831),
}


def standardize(feature: str, raw_value: float) -> float:
    """원본 수치를 z-score 표준화"""
    mean, scale = SCALER_STATS[feature]
    return (raw_value - mean) / scale


print(f"[모델 로드 완료] 혈당 포함: {type(MODEL_SUGAR).__name__}, "
      f"혈당 미포함: {type(MODEL_NO_SUGAR).__name__}")
