# 혈당 유무에 따라 모델을 분기하여 예측 + 차트 생성
from __future__ import annotations

import base64
import io

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from fastapi import HTTPException

from app.model_loader import (
    ALIAS_TO_ENG,
    FEATURE_LABELS,
    FEATURE_RANGES,
    FEATURES_NO_SUGAR,
    FEATURES_SUGAR,
    MODEL_NO_SUGAR,
    MODEL_SUGAR,
    standardize,
)
from app.schemas import PredictRequest, PredictResponse

matplotlib.use("Agg")
plt.rcParams["font.family"] = "AppleGothic"
plt.rcParams["axes.unicode_minus"] = False


def create_chart_base64(
    probability: float,
    input_values: dict[str, float],
    model,
    feature_names: list[str],
) -> str:
    """당뇨/정상 확률 + 피처 중요도(또는 입력값) 차트"""
    fig, axes = plt.subplots(2, 1, figsize=(6, 7))

    # 상단: 당뇨/정상 확률 바 차트
    ax1 = axes[0]
    diabetes_prob = max(0.0, min(1.0, probability))
    normal_prob = 1.0 - diabetes_prob
    labels = ["정상 가능성", "당뇨 가능성"]
    values = [normal_prob, diabetes_prob]
    colors = ["#4CAF50", "#E53935"]

    bars = ax1.bar(labels, values, color=colors)
    ax1.set_ylim(0, 1)
    ax1.set_ylabel("확률")
    ax1.set_title("당뇨 예측 결과 (ML 모델)")

    for bar, value in zip(bars, values):
        ax1.text(
            bar.get_x() + bar.get_width() / 2,
            value + 0.02,
            f"{value * 100:.1f}%",
            ha="center",
            va="bottom",
            fontsize=11,
        )

    # 하단: 피처 중요도 또는 입력값
    ax2 = axes[1]
    chart_labels = [FEATURE_LABELS.get(k, k) for k in feature_names]

    if hasattr(model, "feature_importances_"):
        importances = model.feature_importances_
        imp_colors = [
            "#1976D2" if imp < 0.1 else "#FF9800" if imp < 0.2 else "#E53935"
            for imp in importances
        ]
        bars2 = ax2.barh(chart_labels, importances, color=imp_colors)
        ax2.set_xlim(0, max(importances) * 1.3)
        ax2.set_xlabel("중요도")
        ax2.set_title("피처 중요도 (Feature Importance)")
        ax2.invert_yaxis()
        for bar, imp in zip(bars2, importances):
            ax2.text(
                imp + 0.005,
                bar.get_y() + bar.get_height() / 2,
                f"{imp:.3f}",
                ha="left",
                va="center",
                fontsize=9,
            )
    else:
        input_vals = [input_values.get(k, 0.0) for k in feature_names]
        bar_colors = ["#1976D2" if v > 0 else "#9E9E9E" for v in input_vals]
        bars2 = ax2.barh(chart_labels, input_vals, color=bar_colors)
        ax2.set_xlabel("입력값")
        ax2.set_title("입력 항목별 수치")
        ax2.invert_yaxis()
        for bar, val in zip(bars2, input_vals):
            if val > 0:
                ax2.text(
                    val + 0.5,
                    bar.get_y() + bar.get_height() / 2,
                    f"{val:.1f}",
                    ha="left",
                    va="center",
                    fontsize=9,
                )

    fig.tight_layout()

    buf = io.BytesIO()
    fig.savefig(buf, format="png", dpi=150)
    plt.close(fig)
    buf.seek(0)
    return base64.b64encode(buf.read()).decode("utf-8")


def predict_with_model(payload: PredictRequest) -> PredictResponse:
    """혈당 유무에 따라 모델을 분기하여 예측"""

    # 입력값 수집 (영문 키 기준)
    raw_input: dict[str, float | None] = {
        "pregnancies": payload.pregnancies,
        "glucose": payload.glucose,
        "bmi": payload.bmi,
        "age": payload.age,
    }

    user_provided = {k: float(v) for k, v in raw_input.items() if v is not None}

    if not user_provided:
        raise HTTPException(status_code=400, detail="최소 1개 이상의 입력 항목이 필요합니다.")

    # 범위 검증
    for key, value in user_provided.items():
        if key in FEATURE_RANGES:
            min_v, max_v = FEATURE_RANGES[key]
            if value < min_v or value > max_v:
                label = FEATURE_LABELS.get(key, key)
                raise HTTPException(
                    status_code=400,
                    detail=f"{label}({key}) 값은 {min_v} ~ {max_v} 범위여야 합니다.",
                )

    # 혈당 포함 여부에 따라 모델 분기
    has_glucose = "glucose" in user_provided
    if has_glucose:
        model = MODEL_SUGAR
        feature_names = FEATURES_SUGAR
        used_model_name = "AdaBoost (혈당 포함)"
    else:
        model = MODEL_NO_SUGAR
        feature_names = FEATURES_NO_SUGAR
        used_model_name = "RandomForest (혈당 미포함)"

    # 피처에 해당하는 값이 최소 1개는 있어야 함
    active_count = sum(1 for k in feature_names if k in user_provided)
    if active_count == 0:
        raise HTTPException(
            status_code=400,
            detail=f"현재 모델에서 사용하는 항목이 입력되지 않았습니다. "
                   f"필요 항목: {', '.join(feature_names)}",
        )

    # 원본 수치 -> StandardScaler 표준화 (학습 시 파이프라인과 동일)
    x_values = [
        standardize(f, user_provided.get(f, 0.0))
        for f in feature_names
    ]
    X = np.array([x_values])

    # 예측
    proba = model.predict_proba(X)[0]
    probability = float(proba[1])
    prediction = int(probability >= 0.5)
    label = "당뇨 위험" if prediction == 1 else "정상 범위"

    # 차트 생성
    chart_image_base64: str | None = None
    try:
        chart_image_base64 = create_chart_base64(
            probability, user_provided, model, feature_names,
        )
    except Exception:
        chart_image_base64 = None

    return PredictResponse(
        prediction=prediction,
        probability=round(probability, 4),
        label=label,
        input=user_provided,
        used_model=used_model_name,
        chart_image_base64=chart_image_base64,
    )
