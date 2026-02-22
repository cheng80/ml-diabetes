from __future__ import annotations

import json
from pathlib import Path

import joblib

APP_DIR = Path(__file__).resolve().parent

FEATURES_DETAIL_SUGAR = ["pregnancies", "glucose", "bmi", "age"]
FEATURES_DETAIL_NO_SUGAR = ["pregnancies", "bmi", "age"]
FEATURES_SIMPLE_SUGAR = ["pregnancies", "glucose", "bmi", "age"]
FEATURES_SIMPLE_NO_SUGAR = ["pregnancies", "bmi", "age"]

# 구버전 호환 alias
FEATURES_SUGAR = FEATURES_DETAIL_SUGAR
FEATURES_NO_SUGAR = FEATURES_DETAIL_NO_SUGAR

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

def _load_required(path: Path, label: str):
    if not path.exists():
        raise FileNotFoundError(f"{label} 파일을 찾을 수 없습니다: {path}")
    return joblib.load(path)


def _load_optional(path: Path):
    if not path.exists():
        return None
    return joblib.load(path)


def _load_json(path: Path):
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


# ---------------------------------------------------------------------------
# 4-시나리오 아티팩트 (A/B/C/C-NS)
# ---------------------------------------------------------------------------
MODEL_DETAIL_SUGAR = _load_optional(APP_DIR / "a_detail_sugar_model.joblib")
SCALER_DETAIL_SUGAR = _load_optional(APP_DIR / "a_detail_sugar_scaler.joblib")
IMPUTER_DETAIL_SUGAR = _load_optional(APP_DIR / "a_detail_sugar_imputer.joblib")
CLIP_BOUNDS_DETAIL_SUGAR = _load_optional(APP_DIR / "a_detail_sugar_clip_bounds.joblib")

MODEL_DETAIL_NO_SUGAR = _load_optional(APP_DIR / "b_detail_no_sugar_model.joblib")
SCALER_DETAIL_NO_SUGAR = _load_optional(APP_DIR / "b_detail_no_sugar_scaler.joblib")
IMPUTER_DETAIL_NO_SUGAR = _load_optional(APP_DIR / "b_detail_no_sugar_imputer.joblib")
CLIP_BOUNDS_DETAIL_NO_SUGAR = _load_optional(APP_DIR / "b_detail_no_sugar_clip_bounds.joblib")

MODEL_SIMPLE_SUGAR = _load_optional(APP_DIR / "c_simple_sugar_model.joblib")
QUANTILES_SIMPLE_SUGAR = _load_optional(APP_DIR / "c_simple_sugar_quantiles.joblib")

MODEL_SIMPLE_NO_SUGAR = _load_optional(APP_DIR / "cns_simple_no_sugar_model.joblib")
QUANTILES_SIMPLE_NO_SUGAR = _load_optional(APP_DIR / "cns_simple_no_sugar_quantiles.joblib")
SCENARIO_META = _load_json(APP_DIR / "model_scenarios_meta.json")

# ---------------------------------------------------------------------------
# 런타임 기본 모델 (기존 API 호환)
# ---------------------------------------------------------------------------
MODEL_SUGAR = _load_required(APP_DIR / "model_sugar.joblib", "혈당 포함 모델")
MODEL_NO_SUGAR = _load_required(APP_DIR / "model_no_sugar.joblib", "혈당 미포함 모델")

# ---------------------------------------------------------------------------
# Legacy 표준화 fallback (신규 scaler/imputer가 없을 때만 사용)
# ---------------------------------------------------------------------------
SCALER_STATS: dict[str, tuple[float, float]] = {
    "pregnancies": (3.837240, 3.341979),
    "glucose": (121.686763, 30.515624),
    "bmi": (32.394716, 6.711356),
    "age": (33.199870, 11.620831),
}


def standardize(feature: str, raw_value: float) -> float:
    mean, scale = SCALER_STATS[feature]
    return (raw_value - mean) / scale


def to_simple_grade(feature_eng: str, value: float, quantiles: dict[str, list[float]]) -> int:
    """간편(C/C-NS) 시나리오용 분위수 등급화 (1~4)"""
    feature_kor = FEATURE_LABELS[feature_eng]
    q = quantiles[feature_kor]
    if value <= q[0]:
        return 1
    if value <= q[1]:
        return 2
    if value <= q[2]:
        return 3
    return 4


def get_scenario_threshold(key: str) -> float:
    if not SCENARIO_META:
        return 0.5
    scenario = SCENARIO_META.get("scenarios", {}).get(key)
    if not scenario:
        return 0.5
    try:
        return float(scenario.get("threshold", 0.5))
    except Exception:
        return 0.5


def _typename(obj) -> str:
    return type(obj).__name__ if obj is not None else "None"


print(
    "[모델 로드 완료] "
    f"default_sugar={_typename(MODEL_SUGAR)}, "
    f"default_no_sugar={_typename(MODEL_NO_SUGAR)}, "
    f"A={_typename(MODEL_DETAIL_SUGAR)}, "
    f"B={_typename(MODEL_DETAIL_NO_SUGAR)}, "
    f"C={_typename(MODEL_SIMPLE_SUGAR)}, "
    f"C_NS={_typename(MODEL_SIMPLE_NO_SUGAR)}"
)
