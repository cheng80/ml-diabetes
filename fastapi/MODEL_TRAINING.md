# FastAPI 구조 문서

---

## 1. 안내

- Python 학습/모델 관련 내용은 모두 제거했습니다.
- FastAPI 세부 설계(Endpoint, Schema, 로직)는 이후 별도 작성 예정입니다.
- 본 문서는 **FastAPI 폴더 구조만 유지**합니다.

---

## 2. FastAPI 폴더 구조

```text
fastapi/
├── MODEL_TRAINING.md       # 구조 문서 (현재 파일)
└── app/
    ├── __init__.py
    ├── main.py             # Endpoint 정의 예정
    ├── schemas.py          # 요청/응답 스키마 예정
    ├── model_loader.py     # 모델 로딩 로직 예정
    └── predictor.py        # 예측 처리 로직 예정
```
