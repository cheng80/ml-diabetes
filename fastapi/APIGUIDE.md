# 당뇨 예측 FastAPI 가이드 (API GUIDE)

이 문서는 Flutter 앱(프론트엔드)과 통신하기 위해 구성된 FastAPI 백엔드 서버의 엔드포인트 및 스키마 명세서입니다.

---

## 🚀 서버 실행 방법

### 개발 모드 실행
```bash
cd fastapi
source .venv/bin/activate
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
> **참고**: 실기기(Flutter)에서 테스트할 경우, `--host 0.0.0.0`으로 실행해야 동일 네트워크 내에서 IP를 통해 접근할 수 있습니다.

### Swagger UI (API 문서 테스트)
서버 실행 후 브라우저에서 아래 주소로 접속하면, 내장된 Swagger UI를 통해 직접 API를 테스트해 볼 수 있습니다.
- **URL**: `http://localhost:8000/docs`

---

## 📡 API 엔드포인트 명세

### 1. 상태 및 정보 확인 (Health Check)
서버의 현재 상태 및 서빙 중인 머신러닝 모델의 기본 메타데이터를 반환합니다. 실기기 연결을 위해 서버의 Local IP 주소도 함께 안내합니다.

- **URL**: `/health`
- **Method**: `GET`
- **응답 예시 (200 OK)**:
```json
{
  "status": "ok",
  "model_sugar": "AdaBoostClassifier (혈당 포함, Acc 0.81)",
  "model_no_sugar": "RandomForestClassifier (혈당 미포함, Acc 0.71)",
  "local_ip": "192.168.0.15",
  "suggested_url": "http://192.168.0.15:8000"
}
```

---

### 2. 당뇨 예측 요청 (Predict)
입력받은 사용자 데이터를 바탕으로 당뇨 위험도 확률 및 차트 이미지를 반환합니다.
- 영문 키(`age`, `bmi`)와 한글 키(`나이`, `BMI`) **모두 사용 가능**합니다. (Pydantic의 `populate_by_name` 활용)

- **URL**: `/predict`
- **Method**: `POST`
- **요청 본문 (JSON)**: 최소 1개 이상의 데이터가 포함되어야 합니다.
```json
{
  "나이": 45,
  "BMI": 28.5,
  "임신횟수": 2.0,
  "혈당": 140.0
}
```

- **응답 본문 (200 OK)**:
```json
{
  "prediction": 1,
  "probability": 0.546,
  "label": "당뇨 위험",
  "input": {
    "age": 50.0,
    "bmi": 33.6,
    "pregnancies": 6.0,
    "glucose": 148.0
  },
  "used_model": "AdaBoost (혈당 포함)",
  "chart_image_base64": "iVBORw0KGgoAAAANSUhEUgAA..." 
}
```
> `chart_image_base64`: Flutter 측에서 `Image.memory(base64Decode(chart_image_base64))` 형태로 즉시 렌더링 가능한 모델 차트 이미지(PNG) 데이터입니다.

- **에러 응답**:
  - `400 Bad Request`: 입력값이 전혀 없거나, 값이 허용 범위를 초과한 경우.

---

### 3. 주소 좌표 변환 (Geocoding)
한글 주소 텍스트를 받아 위도(latitude)와 경도(longitude)로 변환해 줍니다. 
- 내부적으로 `geopy`의 Nominatim 오픈 API를 사용하며, 별도의 가입이나 키 발급이 불필요합니다.

- **URL**: `/geocode`
- **Method**: `POST`
- **요청 본문 (JSON)**:
```json
{
  "address": "서울특별시 송파구 중대로 191"
}
```

- **응답 본문 (200 OK)**:
```json
{
  "lat": "37.4990789571513",
  "lng": "127.125683181707"
}
```

- **에러 응답**:
  - `404 Not Found`: 해당 주소에 대한 좌표를 찾지 못했거나 타임아웃이 발생한 경우.

---

## 📁 프로젝트 내부 구조

```text
fastapi/
├── APIGUIDE.md            # API 명세 및 가이드 (현재 문서)
├── requirements.txt       # 파이썬 패키지 의존성
└── app/
    ├── main.py            # FastAPI 앱 초기화 및 엔드포인트 매핑
    ├── schemas.py         # Pydantic을 활용한 입출력 데이터 타입 정의
    ├── predictor.py       # 머신러닝 예측 로직 + Matplotlib 차트 생성 기능
    ├── geocoding.py       # Nominatim 주소 검색 로직
    ├── model_loader.py    # joblib 모델 로드 + StandardScaler 전처리 함수
    ├── model_sugar.joblib # 혈당 포함 모델 (AdaBoost, Acc 0.81)
    └── model_no_sugar.joblib # 혈당 제외 모델 (RandomForest, Acc 0.71)
```