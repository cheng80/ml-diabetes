/// 앱 전역 상수 (API 키, URL 등)
class AppConfig {
  AppConfig._();

  // ─── 공공데이터 API (병원) ─────────────────
  /// 병원정보서비스 API 서비스키
  static const String dataGoKrHospitalServiceKey =
      '0d03508ebb5909e22ed3fc1e267969327c6fb623294c05a7f878c5c5b174bbdc';

  /// 병원정보서비스 API 베이스 URL
  static const String dataGoKrHospitalBaseUrl =
      'https://apis.data.go.kr/B552657/HsptlAsembySearchService/getHsptlMdcncLcinfoInqire';

  // ─── FastAPI ───────────────────────────────
  /// FastAPI 서버 기본 URL (iOS 시뮬레이터/로컬)
  static const String fastApiBaseUrlIos = 'http://127.0.0.1:8000';

  /// FastAPI 서버 기본 URL (Android 에뮬레이터)
  static const String fastApiBaseUrlAndroid = 'http://10.0.2.2:8000';
}
