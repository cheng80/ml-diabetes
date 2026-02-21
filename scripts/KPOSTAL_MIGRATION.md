# kpostal 패키지 적용 가이드 (remedi_kopo 대체)

한글 주소 검색 + 좌표 변환을 위해 `remedi_kopo` 대신 `kpostal`을 사용하는 방법입니다.

## 왜 kpostal?

| 구분 | remedi_kopo | kpostal |
|------|-------------|---------|
| API 키 | 불필요 | 불필요 |
| WebView | webview_flutter (구버전, AGP8 비호환) | flutter_inappwebview (AGP8 호환) |
| Android 빌드 | pub-cache 패치 필요 | 패치 없이 빌드 가능 |
| 유지보수 | 3년 전 업데이트 | 16개월 전 업데이트 |

---

## 1. pubspec.yaml 수정

```yaml
dependencies:
  # 제거
  # remedi_kopo: ^0.0.2

  # 추가
  kpostal: ^1.1.0
```

---

## 2. 코드 수정

### import 변경

```dart
// 제거
import 'package:remedi_kopo/remedi_kopo.dart';

// 추가
import 'package:kpostal/kpostal.dart';
```

### 주소 검색 호출부 변경

**Before (remedi_kopo)**

```dart
final KopoModel? model = await Navigator.push(
  context,
  CupertinoPageRoute(
    builder: (context) => RemediKopo(),
  ),
);

if (model != null && mounted) {
  setState(() {
    _postcodeController.text = model.zonecode ?? '';
    _addressController.text = model.address ?? '';
    _addressDetailController.text = model.buildingName ?? '';
  });
}
```

**After (kpostal)**

```dart
final Kpostal? result = await Navigator.push<Kpostal>(
  context,
  MaterialPageRoute(
    builder: (context) => KpostalView(),
  ),
);

if (result != null && mounted) {
  setState(() {
    _postcodeController.text = result.postCode;
    _addressController.text = result.userSelectedAddress;
    _addressDetailController.text = result.buildingName;
  });
}
```

### 필드 매핑표

| remedi_kopo (KopoModel) | kpostal (Kpostal) |
|------------------------|-------------------|
| `zonecode` | `postCode` |
| `address` | `userSelectedAddress` (도로명/지번 중 사용자 선택값) |
| `buildingName` | `buildingName` |

### 추가 필드 (kpostal)

필요 시 아래 필드도 사용 가능합니다.

- `roadAddress` / `jibunAddress` : 도로명 / 지번 주소
- `latitude` / `longitude` : 플랫폼 geocoding 좌표 (비동기 `latLng` getter로 설정됨)
- `kakaoLatitude` / `kakaoLongitude` : 카카오 API 좌표 (`kakaoKey` 설정 시)

### 좌표 변환 / 저장 버튼이 분리된 경우

좌표 변환 버튼과 저장 버튼이 따로 있는 UI라면:

- **좌표 변환 버튼**: kpostal 결과의 `latitude`, `longitude`가 있으면 그대로 사용. 없을 때만 `/geocode` 호출.
- **저장 버튼**: 이미 변환된 좌표를 저장.

```dart
double? _lastSearchLat;
double? _lastSearchLng;

// 검색 결과에서 좌표 보관
if (result != null) {
  _lastSearchLat = result.latitude;
  _lastSearchLng = result.longitude;
}

// 좌표 변환 버튼
void _onConvertCoordinates() {
  if (_lastSearchLat != null && _lastSearchLng != null) {
    // kpostal 좌표 사용 → UI에 표시
    setState(() { /* lat, lng 표시 */ });
  } else {
    // 서버 /geocode 호출
  }
}

// 저장 버튼: 이미 변환된 좌표로 저장
```

### 좌표 변환·저장이 한 버튼인 경우

kpostal은 주소 선택 시 플랫폼 geocoding으로 `latitude`, `longitude`를 이미 제공합니다.  
저장 시 이 좌표를 쓰면 FastAPI `/geocode` 호출을 생략할 수 있어, Nominatim 503 오류를 피할 수 있습니다.

```dart
// 검색 결과에서 좌표 저장
double? _lastSearchLat;
double? _lastSearchLng;

if (result != null) {
  _lastSearchLat = result.latitude;
  _lastSearchLng = result.longitude;
}

// 저장 시: 좌표가 있으면 서버 호출 생략
if (_lastSearchLat != null && _lastSearchLng != null) {
  // 바로 저장
} else {
  // 서버 /geocode 호출
}
```

---

## 3. 빌드 및 확인

```bash
flutter pub get
flutter build apk --debug   # 또는 --release
```

패치 스크립트 없이 빌드됩니다.

---

## 4. 참고

- **디버그 로그**: kpostal은 `dart:developer`의 `dev.log()`를 사용합니다. 디버그 콘솔에 출력되며, 릴리즈 빌드에서는 IDE 디버그 콘솔에는 표시되지 않습니다.
- **카카오 좌표**: `KpostalView(kakaoKey: '...')`로 카카오 JS 키를 넘기면 `kakaoLatitude`, `kakaoLongitude`를 사용할 수 있습니다. 기본값은 플랫폼 geocoding입니다.
- **로컬 서버**: `useLocalServer: true`로 설정하면 외부 호스팅 문제 시에도 동작합니다. 이 경우 Android `usesCleartextTraffic`, iOS `NSAppTransportSecurity` 설정이 필요할 수 있습니다.
