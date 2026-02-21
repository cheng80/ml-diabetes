# webview_flutter_android 패치 (Android AGP8 호환)

## 개요

`remedi_kopo`(카카오 주소검색 API)가 의존하는 `webview_flutter`는 구버전 `webview_flutter_android`(2.10.4)를 끌어옵니다.  
이 패키지는 Android Gradle Plugin 8+ 환경에서 아래 오류를 일으킵니다.

- `Namespace not specified` (build.gradle)
- `package` 속성 사용 불가 (AndroidManifest.xml)
- `PluginRegistry.Registrar` 제거됨 (Flutter v1 embedding)

이 스크립트는 pub-cache의 해당 패키지를 자동으로 패치하여 Android 빌드를 가능하게 합니다.

---

## 사용법

### 기본 흐름

```bash
# 1) 의존성 설치
flutter pub get

# 2) 패치 실행 (프로젝트 루트에서)
./scripts/patch_webview_for_android.sh

# 3) 빌드
flutter build apk --debug
# 또는
flutter build apk --release
```

### 다른 프로젝트에 적용

1. `scripts/` 폴더와 `patch_webview_for_android.sh`를 해당 프로젝트로 복사
2. 해당 프로젝트 루트에서 `flutter pub get` 실행
3. `./scripts/patch_webview_for_android.sh` 실행
4. 빌드

### flutter pub cache repair 후

`flutter pub cache repair`를 실행하면 pub-cache가 초기화되어 패치가 사라집니다.  
다시 아래 순서로 진행하세요.

```bash
flutter pub get
./scripts/patch_webview_for_android.sh
```

---

## 패치 내용

| 대상 | 변경 사항 |
|------|-----------|
| `build.gradle` | `namespace 'io.flutter.plugins.webviewflutter'` 추가 (AGP 8+ 필수) |
| `AndroidManifest.xml` | `package` 속성 제거 (AGP 8 권장사항) |
| `FlutterAssetManager.java` | v1 embedding용 `RegistrarFlutterAssetManager` 클래스 제거 |
| `WebViewFlutterPlugin.java` | `registerWith(PluginRegistry.Registrar)` 메서드 제거 |

---

## 참고 사항

- **pub-cache는 전역**입니다. 한 번 패치하면 같은 PC의 다른 Flutter 프로젝트에서도 적용됩니다.
- **iOS**는 `webview_flutter_wkwebview`를 사용하므로 이 패치가 필요 없습니다.
- **dependency_overrides**로 webview 4.x를 강제하면 `remedi_kopo` API와 비호환되어 빌드가 실패합니다.

---

## CI/CD 연동

`flutter pub get` 직후 스크립트를 실행하도록 설정하세요.

```yaml
# 예: GitHub Actions
- run: flutter pub get
- run: chmod +x scripts/patch_webview_for_android.sh
- run: ./scripts/patch_webview_for_android.sh
- run: flutter build apk --release
```

---

## 트러블슈팅

| 증상 | 대응 |
|------|------|
| `webview_flutter_android 패키지를 찾을 수 없습니다` | `flutter pub get`을 먼저 실행했는지 확인 |
| `Permission denied` | `chmod +x scripts/patch_webview_for_android.sh` 실행 |
| 패치 후에도 빌드 실패 | `flutter clean` 후 `flutter pub get` → `patch_webview_for_android.sh` → `flutter build apk --debug` 재시도 |
