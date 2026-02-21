# 당뇨 위험도 예측 앱

Flutter + FastAPI 기반의 당뇨 위험도 예측 모바일 앱입니다.  
사용자가 간단한 건강 정보를 입력하면 머신러닝 모델이 당뇨 위험 확률을 분석하고,
필요 시 주변 병원 검색과 길찾기까지 연결해 줍니다.

---

## 주요 기능

### 당뇨 위험도 예측
- **간편 예측**: 나이, 키/몸무게(BMI), 임신횟수, 혈당을 라디오 버튼 구간으로 선택
- **상세 예측**: 각 항목을 직접 수치로 입력
- 혈당 수치는 선택 사항이며, 입력 여부에 따라 서로 다른 모델이 적용됨
- 예측 결과를 확률, 판정, 차트 이미지로 제공

### 병원 검색 및 길찾기
- 주소 검색 후 좌표 기반으로 주변 병원 목록 조회 (공공데이터 API)
- 병원 카드에서 길찾기 버튼을 누르면 카카오맵, 네이버지도, 티맵, Apple Maps 등 설치된 지도 앱으로 바로 연결

### 기타
- 다크 모드 / 라이트 모드 전환
- API 서버 주소 사용자 지정 (실기기 테스트 대응)
- 주소 및 좌표 로컬 저장

---

## 기술 스택

| 구분 | 기술 |
|------|------|
| 프론트엔드 | Flutter (Dart), Material Design 3 |
| 백엔드 | FastAPI (Python) |
| ML 모델 | scikit-learn (AdaBoost, RandomForest) |
| 데이터 시각화 | Matplotlib (서버 사이드 차트 생성, Base64 전송) |
| 주소 검색 | 카카오 주소검색 API (kpostal) |
| 병원 조회 | 공공데이터 건강보험심사평가원 API |
| 좌표 변환 | Nominatim (geopy) |
| 지도 연동 | map_launcher |
| 로컬 저장소 | GetStorage |

---

## 프로젝트 구조

```
diabetes_app/
├── lib/
│   ├── main.dart                          # 앱 진입점
│   ├── config.dart                        # API 키 및 기본 URL 설정
│   ├── view/
│   │   ├── main_tab_page.dart             # 메인 탭 (간편/상세 예측 전환)
│   │   ├── simple_predict_page.dart       # 간편 예측 화면
│   │   ├── detail_predict_page.dart       # 상세 예측 화면
│   │   ├── hospital_search_page.dart      # 병원 검색 + 길찾기
│   │   └── address_search_page.dart       # 주소 검색 + 좌표 변환
│   ├── model/
│   │   └── hospital.dart                  # 병원 데이터 모델
│   ├── widgets/
│   │   ├── app_settings_drawer.dart       # 설정 드로어 (테마, API URL)
│   │   ├── age_picker.dart                # 나이 선택 (Cupertino 휠)
│   │   ├── height_weight_picker.dart      # 키/몸무게 입력 및 BMI 자동 계산
│   │   └── percentile_range_radio.dart    # 분위 구간 라디오 버튼
│   ├── constants/
│   │   └── diabetes_predict_mapping.dart  # 혈당/임신횟수 구간 매핑
│   ├── utils/
│   │   ├── app_storage.dart               # GetStorage 래퍼
│   │   ├── custom_common_util.dart        # 공통 유틸 (로딩, 스낵바, 검증 등)
│   │   ├── json/custom_json_util.dart     # JSON 파싱/변환 유틸
│   │   └── xml/custom_xml_util.dart       # XML 파싱/변환 유틸
│   ├── navigation/
│   │   └── custom_navigation_util.dart    # 커스텀 페이지 전환
│   └── theme/
│       ├── app_theme_colors.dart          # 라이트/다크 테마 색상 정의
│       └── theme_provider.dart            # 테마 상태 관리
│
├── fastapi/
│   ├── app/
│   │   ├── main.py                        # FastAPI 앱 (엔드포인트 정의)
│   │   ├── schemas.py                     # Pydantic 요청/응답 스키마
│   │   ├── predictor.py                   # 예측 로직 + 차트 생성
│   │   ├── model_loader.py                # 모델 로드 + StandardScaler 전처리
│   │   ├── geocoding.py                   # 주소 → 좌표 변환
│   │   ├── model_sugar.joblib             # 혈당 포함 모델 (AdaBoost)
│   │   └── model_no_sugar.joblib          # 혈당 미포함 모델 (RandomForest)
│   ├── requirements.txt
│   ├── APIGUIDE.md                        # API 명세 문서
│   └── MODEL_FIX_REPORT.md               # 모델 수정 보고서
│
├── android/                               # Android 플랫폼
├── ios/                                   # iOS 플랫폼
└── pubspec.yaml                           # Flutter 의존성
```

---

## 실행 방법

### 1. FastAPI 백엔드 서버

```bash
cd fastapi
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

서버 실행 후 `http://localhost:8000/docs`에서 Swagger UI로 API를 테스트할 수 있습니다.

### 2. Flutter 앱

```bash
flutter pub get
flutter run
```

실기기에서 테스트할 경우, 앱 설정 드로어에서 API 서버 주소를 PC의 로컬 IP로 변경해야 합니다.  
서버의 `/health` 엔드포인트 응답에서 `suggested_url`을 확인할 수 있습니다.

---

## API 엔드포인트

| Method | URL | 설명 |
|--------|-----|------|
| GET | `/health` | 서버 상태 및 모델 정보 확인 |
| POST | `/predict` | 당뇨 위험도 예측 (확률, 판정, 차트) |
| POST | `/geocode` | 한글 주소 → 위도/경도 변환 |

요청/응답 상세는 [APIGUIDE.md](fastapi/APIGUIDE.md)를 참고하세요.

---

## ML 모델

Pima Indians Diabetes Dataset(당뇨.csv)을 기반으로 학습한 두 가지 모델을 사용합니다.

| 시나리오 | 모델 | 입력 피처 | Test Accuracy |
|----------|------|-----------|---------------|
| 혈당 포함 | AdaBoost | 혈당, BMI, 나이, 임신횟수 | 0.81 |
| 혈당 미포함 | RandomForest | BMI, 나이, 임신횟수 | 0.71 |

API에서 사용자 입력(원본 수치)을 받으면 학습 시와 동일한 StandardScaler 표준화를 적용한 뒤 모델에 전달합니다.  
모델 수정 이력과 전처리 파이프라인 상세는 [MODEL_FIX_REPORT.md](fastapi/MODEL_FIX_REPORT.md)를 참고하세요.

---

## 네이티브 권한 설정

외부 지도 앱 호출을 위해 플랫폼별 설정이 필요합니다.

**iOS** (`ios/Runner/Info.plist`) - `LSApplicationQueriesSchemes`에 `kakaomap`, `nmap`, `tmap`, `comgooglemaps`, `maps` 등록

**Android** (`android/app/src/main/AndroidManifest.xml`) - `<queries>` 블록에 `kakaomap`, `nmap`, `tmap` 인텐트 선언

---

## 개발 환경

- Flutter SDK >= 3.10.8
- Python 3.10+
- scikit-learn, FastAPI, uvicorn
- 실기기 테스트 권장 (지도 앱 연동은 시뮬레이터에서 불가)
