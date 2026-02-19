# 당뇨 예측 모델 학습 (채혈 없이 가능한 피처 조합 + 하이퍼파라미터 탐색)
# 사용: cd fastapi && source .venv/bin/activate && python train_model.py
from __future__ import annotations

import warnings
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.discriminant_analysis import QuadraticDiscriminantAnalysis
from sklearn.ensemble import AdaBoostClassifier, RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    f1_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import ParameterGrid, train_test_split
from sklearn.naive_bayes import GaussianNB
from sklearn.neighbors import KNeighborsClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.svm import SVC
from sklearn.tree import DecisionTreeClassifier

# 1. 원본 데이터 (평균/표준편차 추출)
ORIG_CSV_PATH = Path("/Users/cheng80/Desktop/당뇨.csv")
if not ORIG_CSV_PATH.exists():
    raise FileNotFoundError(f"원본 CSV 파일을 찾을 수 없습니다: {ORIG_CSV_PATH}")

df_orig = pd.read_csv(ORIG_CSV_PATH)

COLUMN_MAP = {
    "임신횟수": "pregnancies",
    "혈당": "glucose",
    "혈압": "blood_pressure",
    "피부두께": "skin_thickness",
    "인슐린": "insulin",
    "BMI": "bmi",
    "가족력지표": "pedigree",
    "나이": "age",
    "당뇨": "diabetes",
}
df_orig.rename(columns=COLUMN_MAP, inplace=True)

ALL_FEATURE_NAMES = [
    "pregnancies", "glucose", "blood_pressure", "skin_thickness",
    "insulin", "bmi", "pedigree", "age",
]
TARGET = "diabetes"

orig_means = {}
orig_stds = {}
for col in ALL_FEATURE_NAMES:
    orig_means[col] = float(df_orig[col].mean())
    orig_stds[col] = float(df_orig[col].std())

print(f"[1] 원본 데이터 통계 추출 완료 (평균/표준편차)")
for col in ALL_FEATURE_NAMES:
    print(f"    {col}: mean={orig_means[col]:.4f}, std={orig_stds[col]:.4f}")

# 2. 전처리 데이터 로드
PRE_CSV_PATH = Path("/Users/cheng80/Desktop/diabetes_preprocessed_best.csv")
if not PRE_CSV_PATH.exists():
    raise FileNotFoundError(f"전처리 CSV 파일을 찾을 수 없습니다: {PRE_CSV_PATH}")

df = pd.read_csv(PRE_CSV_PATH)
df.rename(columns=COLUMN_MAP, inplace=True)

print(f"\n[2] 전처리 데이터 로드 완료: {df.shape[0]}행 × {df.shape[1]}열")
print(f"    컬럼: {list(df.columns)}")

# 3. 피처 조합 (채혈 없이 가능한 것 우선)
NO_BLOOD_BASE = [
    "pregnancies",
    "blood_pressure",
    "skin_thickness",
    "bmi",
    "pedigree",
    "age",
]

feature_candidates = {
    "no_blood_all_6": NO_BLOOD_BASE,
    "no_blood_drop_skin": [f for f in NO_BLOOD_BASE if f != "skin_thickness"],
    "no_blood_drop_bp": [f for f in NO_BLOOD_BASE if f != "blood_pressure"],
    "no_blood_drop_preg": [f for f in NO_BLOOD_BASE if f != "pregnancies"],
    "no_blood_lifestyle_4": ["bmi", "pedigree", "age", "skin_thickness"],
    "no_blood_minimal_3": ["bmi", "pedigree", "age"],
}

y = df[TARGET].values
print(f"\n[3] 피처 후보 준비 완료: {len(feature_candidates)}개 조합")
print(f"    타겟 분포: 정상(0)={np.sum(y == 0)}, 당뇨(1)={np.sum(y == 1)}")

# 4. 학습/테스트 분할
idx = np.arange(len(df))
idx_train, idx_test, y_train, y_test = train_test_split(
    idx, y, test_size=0.2, random_state=42, stratify=y,
)
print(f"\n[4] 데이터 분할: 학습 {idx_train.shape[0]}개, 테스트 {idx_test.shape[0]}개")

# 5. 모델·하이퍼파라미터 탐색
print("\n" + "=" * 70)
print(" 5. 피처 + 하이퍼파라미터 탐색")
print("=" * 70)

model_spaces = {
    "KNeighborsClassifier": (
        KNeighborsClassifier,
        {
            "n_neighbors": [3, 5, 7, 9, 11],
            "weights": ["uniform", "distance"],
            "p": [1, 2],
        },
    ),
    "SVC": (
        SVC,
        {
            "kernel": ["rbf"],
            "C": [0.5, 1.0, 2.0, 5.0],
            "gamma": ["scale", 0.1, 0.01],
            "probability": [True],
            "random_state": [42],
        },
    ),
    "DecisionTreeClassifier": (
        DecisionTreeClassifier,
        {
            "max_depth": [3, 4, 5, 6, None],
            "min_samples_leaf": [1, 2, 4],
            "random_state": [42],
        },
    ),
    "RandomForestClassifier": (
        RandomForestClassifier,
        {
            "n_estimators": [200, 300],
            "max_depth": [4, 6, 8, None],
            "min_samples_leaf": [1, 2],
            "random_state": [42],
        },
    ),
    "AdaBoostClassifier": (
        AdaBoostClassifier,
        {
            "n_estimators": [100, 200, 300],
            "learning_rate": [0.01, 0.05, 0.1, 0.5, 1.0],
            "random_state": [42],
        },
    ),
    "MLPClassifier": (
        MLPClassifier,
        {
            "hidden_layer_sizes": [(16,), (32,), (32, 16), (64, 32)],
            "alpha": [1e-4, 1e-3, 1e-2],
            "learning_rate_init": [0.001, 0.01],
            "max_iter": [2000],
            "random_state": [42],
        },
    ),
    "GaussianNB": (
        GaussianNB,
        {
            "var_smoothing": [1e-9, 1e-8, 1e-7],
        },
    ),
    "QuadraticDiscriminantAnalysis": (
        QuadraticDiscriminantAnalysis,
        {
            "reg_param": [0.0, 0.1, 0.2, 0.3],
        },
    ),
}

def total_score(acc: float, auc: float, f1: float, recall: float) -> float:
    # acc 30%, auc 30%, f1 25%, recall 15%
    return acc * 0.30 + auc * 0.30 + f1 * 0.25 + recall * 0.15


def limit_grid(grid: list[dict], max_configs: int = 16) -> list[dict]:
    if len(grid) <= max_configs:
        return grid
    rng = np.random.default_rng(42)
    picked = rng.choice(len(grid), size=max_configs, replace=False)
    return [grid[i] for i in sorted(picked)]


results: list[dict] = []
warnings.filterwarnings("ignore")

for feature_set_name, features in feature_candidates.items():
    X_all = df[features].values
    X_train = X_all[idx_train]
    X_test = X_all[idx_test]

    print(f"\n[탐색] feature_set={feature_set_name}, features={features}")

    for model_name, (model_cls, param_space) in model_spaces.items():
        param_grid = list(ParameterGrid(param_space))
        param_grid = limit_grid(param_grid, max_configs=16)

        for params in param_grid:
            try:
                model = model_cls(**params)
                model.fit(X_train, y_train)
                y_pred = model.predict(X_test)
                y_proba = model.predict_proba(X_test)[:, 1]

                acc = accuracy_score(y_test, y_pred)
                auc = roc_auc_score(y_test, y_proba)
                f1 = f1_score(y_test, y_pred, zero_division=0)
                recall = recall_score(y_test, y_pred, zero_division=0)
                score = total_score(acc, auc, f1, recall)

                results.append(
                    {
                        "feature_set_name": feature_set_name,
                        "features": features,
                        "model_name": model_name,
                        "params": params,
                        "model": model,
                        "accuracy": acc,
                        "auc_roc": auc,
                        "f1_score": f1,
                        "recall": recall,
                        "total_score": score,
                    }
                )
            except Exception:
                continue

# 6. 결과 비교
print("\n" + "=" * 70)
print(" 6. 모델 비교 결과")
print("=" * 70)
if not results:
    raise RuntimeError("유효한 모델 학습 결과가 없습니다.")

results.sort(key=lambda x: x["total_score"], reverse=True)

print(
    f"\n  {'순위':>3s} {'피처셋':20s} {'모델':28s} "
    f"{'정확도':>8s} {'AUC':>8s} {'F1':>8s} {'Recall':>8s} {'Score':>8s}"
)
print("  " + "-" * 102)
for i, r in enumerate(results[:15], start=1):
    marker = " ★" if i == 1 else ""
    print(
        f"  {i:>3d} {r['feature_set_name'][:20]:20s} {r['model_name'][:28]:28s} "
        f"{r['accuracy']:8.4f} {r['auc_roc']:8.4f} {r['f1_score']:8.4f} "
        f"{r['recall']:8.4f} {r['total_score']:8.4f}{marker}"
    )

best = results[0]
print("\n  ★ 최종 선택")
print(f"    모델={best['model_name']}")
print(f"    피처셋={best['feature_set_name']} -> {best['features']}")
print(f"    하이퍼파라미터={best['params']}")
print(
    "    성능="
    f"accuracy={best['accuracy']:.4f}, "
    f"auc_roc={best['auc_roc']:.4f}, "
    f"f1={best['f1_score']:.4f}, "
    f"recall={best['recall']:.4f}, "
    f"score={best['total_score']:.4f}"
)

# 7. 최고 모델 상세 평가
best_model = best["model"]
best_features = best["features"]
X_best_all = df[best_features].values
X_best_test = X_best_all[idx_test]
y_pred_best = best_model.predict(X_best_test)

print(f"\n{'=' * 70}")
print(" 7. 최고 모델 상세 평가")
print(f"{'=' * 70}")
print(classification_report(y_test, y_pred_best, target_names=["정상(0)", "당뇨(1)"]))

if hasattr(best_model, "feature_importances_"):
    importances = best_model.feature_importances_
    print("  피처 중요도:")
    for fname, imp in sorted(zip(best_features, importances), key=lambda x: -x[1]):
        bar = "█" * int(imp * 50)
        print(f"    {fname:20s} {imp:.4f} {bar}")
else:
    print("  피처 중요도: 해당 모델은 제공하지 않음")

# 8. 모델 저장 (joblib → .h5)
SAVE_PATH = Path(__file__).resolve().parent / "app" / "diabetes_model.h5"

algorithm_name = type(best_model).__name__

save_data = {
    "model": best_model,
    "feature_names": best_features,
    "orig_means": orig_means,
    "orig_stds": orig_stds,
    "preprocessed": True,
    "metadata": {
        "algorithm": algorithm_name,
        "accuracy": round(best["accuracy"], 4),
        "auc_roc": round(best["auc_roc"], 4),
        "f1_score": round(best["f1_score"], 4),
        "recall": round(best["recall"], 4),
        "total_score": round(best["total_score"], 4),
        "train_size": idx_train.shape[0],
        "test_size": idx_test.shape[0],
        "total_features": len(best_features),
        "data_source": "diabetes_preprocessed_best.csv",
        "feature_set_name": best["feature_set_name"],
        "selected_features": best_features,
        "selected_params": best["params"],
        "search_note": "채혈 없는 피처 조합 + 하이퍼파라미터 탐색 결과",
        "all_results": [
            {
                "feature_set_name": r["feature_set_name"],
                "features": r["features"],
                "model_name": r["model_name"],
                "params": r["params"],
                "accuracy": round(r["accuracy"], 4),
                "auc_roc": round(r["auc_roc"], 4),
                "f1_score": round(r["f1_score"], 4),
                "recall": round(r["recall"], 4),
                "total_score": round(r["total_score"], 4),
            }
            for r in results
        ],
    },
}

joblib.dump(save_data, SAVE_PATH)
print(f"\n[8] 모델 저장 완료: {SAVE_PATH}")
print(f"    저장된 모델: {algorithm_name}")
print(f"    파일 크기: {SAVE_PATH.stat().st_size / 1024:.1f} KB")
print(f"    저장 항목: model, feature_names, orig_means, orig_stds, metadata")
print("\n완료!")
