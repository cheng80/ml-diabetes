// app_storage.dart
// GetStorage 기반 화면 간 상태 동기화용 헬퍼
//
// Riverpod 없이 GetStorage만 사용.
// 추후 저장할 항목이 정해지면 여기에 키/메서드를 추가한다.

import 'package:get_storage/get_storage.dart';

/// AppStorage - 화면 간 상태 동기화용 정적 헬퍼
///
/// GetStorage 접근을 한 곳으로 모아 관리한다.
/// 저장할 항목이 늘어나면 여기에 키/메서드를 추가한다.
class AppStorage {
  AppStorage._();

  static GetStorage get _storage => GetStorage();

  // ─── 화면 간 상태 동기화 (추후 저장 항목 추가 예정) ─────────────────
  // 예: 예측 입력값, API URL, 마지막 탭 인덱스 등

  // static const String _keyExample = 'example_key';
  // static String? getExample() => _storage.read<String>(_keyExample);
  // static Future<void> saveExample(String value) => _storage.write(_keyExample, value);

  /// GetStorage 인스턴스 (listenKey 등 직접 접근 시)
  static GetStorage get rawStorage => _storage;

  // ─── 테마 ─────────────────────────────────────
  static const String _keyThemeMode = 'theme_mode';

  /// 저장된 테마 모드 문자열 조회 (light / dark / system)
  static String? getThemeMode() => _storage.read<String>(_keyThemeMode);

  /// 테마 모드 저장
  static Future<void> saveThemeMode(String mode) =>
      _storage.write(_keyThemeMode, mode);

  // ─── API 서버 ───────────────────────────────
  static const String _keyApiBaseUrl = 'api_base_url';

  /// 사용자 지정 API 베이스 URL (null이면 플랫폼 기본값 사용)
  static String? getApiBaseUrl() => _storage.read<String>(_keyApiBaseUrl);

  static Future<void> saveApiBaseUrl(String? value) =>
      value == null || value.trim().isEmpty
          ? _storage.remove(_keyApiBaseUrl)
          : _storage.write(_keyApiBaseUrl, value.trim());

  // ─── 주소 / 좌표 ─────────────────────────────
  static const String _keyAddress = 'saved_address';
  static const String _keyLat = 'saved_lat';
  static const String _keyLng = 'saved_lng';

  /// 저장된 전체 주소 조회
  static String? getAddress() => _storage.read<String>(_keyAddress);

  /// 저장된 위도 조회
  static String? getLat() => _storage.read<String>(_keyLat);

  /// 저장된 경도 조회
  static String? getLng() => _storage.read<String>(_keyLng);

  /// 전체 주소 저장
  static Future<void> saveAddress(String address) =>
      _storage.write(_keyAddress, address);

  /// 좌표 저장 (lat, lng)
  static Future<void> saveCoordinates(String lat, String lng) async {
    await _storage.write(_keyLat, lat);
    await _storage.write(_keyLng, lng);
  }

  // ─── 스토어 리셋 (테스트/디버그용) ─────────────────
  /// 전체 저장소 초기화
  static Future<void> clearAll() => _storage.erase();
}
