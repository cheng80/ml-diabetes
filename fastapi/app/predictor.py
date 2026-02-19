# 예측 + 차트 생성. 정규화: (입력 - 평균) / 표준편차
from __future__ import annotations

import base64
import io

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
from fastapi import HTTPException

from app.model_loader import (
    FEATURE_DEFAULTS,
    FEATURE_LABELS,
    FEATURE_NAMES,
    FEATURE_RANGES,
    MODEL,
    ORIG_MEANS,
    ORIG_STDS,
)
from app.schemas import PredictRequest, PredictResponse

matplotlib.use("Agg")
plt.rcParams["font.family"] = "AppleGothic"
plt.rcParams["axes.unicode_minus"] = False


def create_chart_base64(
    probability: float,
    input_values: dict[str, float],
) -> str:
    """당뇨/정상 확률 + 피처 중요도(또는 입력값) 차트 → Base64 PNG"""
    fig, axes = plt.subplots(2, 1, figsize=(6, 7))

    # 상단: 당뇨/정상 확률
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
    feature_labels = [FEATURE_LABELS.get(k, k) for k in FEATURE_NAMES]

    if hasattr(MODEL, "feature_importances_"):
        importances = MODEL.feature_importances_
        imp_colors = [
            "#1976D2" if imp < 0.1 else "#FF9800" if imp < 0.2 else "#E53935"
            for imp in importances
        ]
        bars2 = ax2.barh(feature_labels, importances, color=imp_colors)
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
        input_vals = [input_values.get(k, 0.0) for k in FEATURE_NAMES]
        bar_colors = ["#1976D2" if v > 0 else "#9E9E9E" for v in input_vals]
        bars2 = ax2.barh(feature_labels, input_vals, color=bar_colors)
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


def predict_with_model(
    payload: PredictRequest,
) -> PredictResponse:
    """입력 검증 → 기본값 채움 → 정규화 → 예측 → 차트 → 응답"""
    all_input_values: dict[str, float | None] = {
        "pregnancies": payload.pregnancies,
        "glucose": payload.glucose,
        "blood_pressure": payload.blood_pressure,
        "skin_thickness": payload.skin_thickness,
        "insulin": payload.insulin,
        "bmi": payload.bmi,
        "pedigree": payload.pedigree,
        "age": payload.age,
    }

    user_provided = {k: float(v) for k, v in all_input_values.items() if v is not None}

    if not user_provided:
        raise HTTPException(status_code=400, detail="최소 1개 이상의 입력 항목이 필요합니다.")

    for key, value in user_provided.items():
        min_v, max_v = FEATURE_RANGES[key]
        if value < min_v or value > max_v:
            raise HTTPException(
                status_code=400,
                detail=f"{key} 값은 {min_v} ~ {max_v} 범위여야 합니다.",
            )

    # 모델 피처 중 최소 1개는 입력 필요
    active_provided_count = sum(1 for k in FEATURE_NAMES if k in user_provided)
    if active_provided_count == 0:
        raise HTTPException(
            status_code=400,
            detail=(
                "현재 모델에서 사용하는 항목이 입력되지 않았습니다. "
                f"사용 가능한 항목: {', '.join(FEATURE_NAMES)}"
            ),
        )

    raw_values = []
    for fname in FEATURE_NAMES:
        if fname in user_provided:
            raw_values.append(user_provided[fname])
        else:
            raw_values.append(FEATURE_DEFAULTS.get(fname, 0.0))

    scaled_values = []
    for fname, raw_val in zip(FEATURE_NAMES, raw_values):
        mean = ORIG_MEANS[fname]
        std = ORIG_STDS[fname]
        if std == 0:
            scaled_values.append(0.0)
        else:
            scaled_values.append((raw_val - mean) / std)

    X = np.array([scaled_values])

    proba = MODEL.predict_proba(X)[0]
    probability = float(proba[1])
    prediction = int(probability >= 0.5)
    label = "당뇨 위험" if prediction == 1 else "정상 범위"

    chart_image_base64: str | None = None
    try:
        chart_image_base64 = create_chart_base64(probability, user_provided)
    except Exception:
        chart_image_base64 = None

    return PredictResponse(
        prediction=prediction,
        probability=round(probability, 4),
        label=label,
        input=user_provided,
        chart_image_base64=chart_image_base64,
    )
