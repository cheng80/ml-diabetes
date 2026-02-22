# 혈당 유무에 따라 모델을 분기하여 예측 + 차트 생성
from __future__ import annotations

import base64
import io

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from fastapi import HTTPException
from sklearn.impute import KNNImputer
from sklearn.preprocessing import StandardScaler

from app.model_loader import (
    CLIP_BOUNDS_DETAIL_NO_SUGAR,
    CLIP_BOUNDS_DETAIL_SUGAR,
    FEATURE_LABELS,
    FEATURE_RANGES,
    FEATURES_DETAIL_NO_SUGAR,
    FEATURES_DETAIL_SUGAR,
    FEATURES_SIMPLE_NO_SUGAR,
    FEATURES_SIMPLE_SUGAR,
    IMPUTER_DETAIL_NO_SUGAR,
    IMPUTER_DETAIL_SUGAR,
    MODEL_DETAIL_NO_SUGAR,
    MODEL_DETAIL_SUGAR,
    MODEL_NO_SUGAR,
    MODEL_SIMPLE_NO_SUGAR,
    MODEL_SIMPLE_SUGAR,
    MODEL_SUGAR,
    QUANTILES_SIMPLE_NO_SUGAR,
    QUANTILES_SIMPLE_SUGAR,
    SCALER_DETAIL_NO_SUGAR,
    SCALER_DETAIL_SUGAR,
    get_scenario_threshold,
    standardize,
    to_simple_grade,
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
    """입력모드(detail/simple) + 혈당 유무에 따라 모델 분기 예측"""

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

    # 혈당 포함 여부 + 입력 모드에 따라 모델 분기
    has_glucose = "glucose" in user_provided
    mode = (payload.input_mode or "detail").lower().strip()
    if mode not in ("detail", "simple"):
        raise HTTPException(status_code=400, detail="입력모드는 detail 또는 simple 이어야 합니다.")

    # 피처에 해당하는 값이 최소 1개는 있어야 함
    if mode == "simple":
        if has_glucose:
            feature_names = FEATURES_SIMPLE_SUGAR
            model = MODEL_SIMPLE_SUGAR or MODEL_SUGAR
            quantiles = QUANTILES_SIMPLE_SUGAR
            used_model_name = "Scenario C (간편/등급형, 혈당 포함)"
            threshold = get_scenario_threshold("C")
        else:
            feature_names = FEATURES_SIMPLE_NO_SUGAR
            model = MODEL_SIMPLE_NO_SUGAR or MODEL_NO_SUGAR
            quantiles = QUANTILES_SIMPLE_NO_SUGAR
            used_model_name = "Scenario C-NS (간편/등급형, 혈당 미포함)"
            threshold = get_scenario_threshold("C_NS")

        active_count = sum(1 for k in feature_names if k in user_provided)
        if active_count == 0:
            raise HTTPException(
                status_code=400,
                detail=f"현재 모델에서 사용하는 항목이 입력되지 않았습니다. 필요 항목: {', '.join(feature_names)}",
            )

        # quantiles가 있으면 노트북 방식(등급화) 적용, 없으면 fallback
        if quantiles:
            row = {
                FEATURE_LABELS[f]: float(
                    to_simple_grade(f, user_provided.get(f, 0.0), quantiles)
                )
                for f in feature_names
            }
            X = pd.DataFrame([row])
        else:
            x_values = [standardize(f, user_provided.get(f, 0.0)) for f in feature_names]
            X = np.array([x_values], dtype=float)
    else:
        if has_glucose:
            feature_names = FEATURES_DETAIL_SUGAR
            model = MODEL_DETAIL_SUGAR or MODEL_SUGAR
            scaler = SCALER_DETAIL_SUGAR
            imputer = IMPUTER_DETAIL_SUGAR
            used_model_name = "Scenario A (상세/수치형, 혈당 포함)"
            clip_bounds = CLIP_BOUNDS_DETAIL_SUGAR
            threshold = get_scenario_threshold("A")
        else:
            feature_names = FEATURES_DETAIL_NO_SUGAR
            model = MODEL_DETAIL_NO_SUGAR or MODEL_NO_SUGAR
            scaler = SCALER_DETAIL_NO_SUGAR
            imputer = IMPUTER_DETAIL_NO_SUGAR
            used_model_name = "Scenario B (상세/수치형, 혈당 미포함)"
            clip_bounds = CLIP_BOUNDS_DETAIL_NO_SUGAR
            threshold = get_scenario_threshold("B")

        active_count = sum(1 for k in feature_names if k in user_provided)
        if active_count == 0:
            raise HTTPException(
                status_code=400,
                detail=f"현재 모델에서 사용하는 항목이 입력되지 않았습니다. 필요 항목: {', '.join(feature_names)}",
            )

        # 신규 상세 모델 전처리(Scaler + Imputer)가 존재하면 우선 사용
        if isinstance(scaler, StandardScaler) and isinstance(imputer, KNNImputer):
            raw_row = []
            for f in feature_names:
                v = user_provided.get(f)
                if v is None or float(v) == 0.0:
                    raw_row.append(np.nan)
                else:
                    raw_row.append(float(v))
            cols_kor = [FEATURE_LABELS[f] for f in feature_names]
            x_raw = pd.DataFrame([raw_row], columns=cols_kor)
            if isinstance(clip_bounds, dict):
                for c in cols_kor:
                    if c in clip_bounds:
                        low, up = clip_bounds[c]
                        x_raw[c] = x_raw[c].clip(low, up)
            x_scaled = scaler.transform(x_raw)
            X = imputer.transform(x_scaled)
        else:
            # legacy fallback
            x_values = [standardize(f, user_provided.get(f, 0.0)) for f in feature_names]
            X = np.array([x_values], dtype=float)
            threshold = 0.5

    # 예측
    proba = model.predict_proba(X)[0]
    probability = float(proba[1])
    prediction = int(probability >= threshold)
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
