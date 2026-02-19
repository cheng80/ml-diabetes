import 'package:diabetes_app/config.dart';
import 'package:diabetes_app/utils/app_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

// 커스텀 공용 유틸리티 클래스
// 위젯 및 공통 기능 관련 유틸리티 함수들을 제공합니다.
class CustomCommonUtil {
  /// FastAPI 서버 URL. 사용자 지정 있으면 그대로, 없으면 플랫폼 기본값
  static String getApiBaseUrlSync() {
    final custom = AppStorage.getApiBaseUrl();
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }
    if (Platform.isAndroid) {
      return AppConfig.fastApiBaseUrlAndroid;
    }
    return AppConfig.fastApiBaseUrlIos;
  }

  // ============================================
  // 위젯 관련 유틸리티
  // ============================================

  // 안전한 setState 호출 헬퍼 함수 (mounted 체크 포함)
  // 비동기 작업 후에도 안전하게 setState를 호출할 수 있습니다
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.safeSetState(this, () {
  //   _isLoading = true;
  // });
  // ```
  static void safeSetState(State state, VoidCallback fn) {
    if (state.mounted) {
      // ignore: invalid_use_of_protected_member
      state.setState(fn);
    }
  }

  // label이 String인지 확인하는 메서드
  //
  // 사용 예시:
  // ```dart
  // if (CustomCommonUtil.isString(label)) {
  //   // String 처리
  //   Text(label as String)
  // } else if (CustomCommonUtil.isWidget(label)) {
  //   // Widget 처리
  //   label as Widget
  // }
  // ```
  static bool isString(dynamic value) {
    return value is String;
  }

  // label이 Widget인지 확인하는 메서드
  //
  // 사용 예시:
  // ```dart
  // if (CustomCommonUtil.isWidget(label)) {
  //   return label as Widget;
  // }
  // ```
  static bool isWidget(dynamic value) {
    return value is Widget;
  }

  // label을 Widget으로 변환하는 메서드
  // String이면 Text 위젯으로, Widget이면 그대로 반환
  //
  // 사용 예시:
  // ```dart
  // final widget = CustomCommonUtil.toWidget(
  //   label,
  //   style: TextStyle(fontSize: 16),
  // );
  // ```
  static Widget toWidget(
    dynamic label, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    if (label is String) {
      return Text(
        label,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    } else if (label is Widget) {
      return label;
    } else {
      throw ArgumentError(
        'label은 String 또는 Widget이어야 합니다. 현재 타입: ${label.runtimeType}',
      );
    }
  }

  // label을 String으로 변환하는 메서드 (가능한 경우)
  // Widget인 경우 null 반환
  //
  // 사용 예시:
  // ```dart
  // final text = CustomCommonUtil.toLabelString(label);
  // if (text != null) {
  //   // String으로 처리
  // }
  // ```
  static String? toLabelString(dynamic label) {
    if (label is String) {
      return label;
    }
    return null;
  }

  // ============================================
  // 날짜/시간 관련 유틸리티 (DateUtil)
  // ============================================

  // 날짜를 지정된 형식으로 포맷팅
  //
  // [date] 포맷팅할 날짜
  // [format] 날짜 형식 (예: 'yyyy-MM-dd', 'yyyy년 MM월 dd일', 'yyyy-MM-dd HH:mm:ss')
  //
  // 지원하는 패턴:
  // - yyyy: 4자리 연도
  // - MM: 2자리 월 (01-12)
  // - dd: 2자리 일 (01-31)
  // - HH: 2자리 시간 (00-23)
  // - mm: 2자리 분 (00-59)
  // - ss: 2자리 초 (00-59)
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.formatDate(DateTime.now(), 'yyyy-MM-dd'); // '2024-01-15'
  // CustomCommonUtil.formatDate(DateTime.now(), 'yyyy년 MM월 dd일'); // '2024년 01월 15일'
  // CustomCommonUtil.formatDate(DateTime.now(), 'yyyy-MM-dd HH:mm:ss'); // '2024-01-15 14:30:00'
  // ```
  static String formatDate(DateTime date, String format) {
    String result = format;

    // 연도
    result = result.replaceAll('yyyy', date.year.toString().padLeft(4, '0'));

    // 월
    result = result.replaceAll('MM', date.month.toString().padLeft(2, '0'));

    // 일
    result = result.replaceAll('dd', date.day.toString().padLeft(2, '0'));

    // 시간
    result = result.replaceAll('HH', date.hour.toString().padLeft(2, '0'));

    // 분
    result = result.replaceAll('mm', date.minute.toString().padLeft(2, '0'));

    // 초
    result = result.replaceAll('ss', date.second.toString().padLeft(2, '0'));

    return result;
  }

  // 시간을 12시간 형식(오전/오후)으로 변환
  //
  // [time] 변환할 시간 (HH:MM 형식 문자열 또는 TimeOfDay)
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.formatTime12Hour("14:30"); // "오후 2:30"
  // CustomCommonUtil.formatTime12Hour(TimeOfDay(hour: 9, minute: 15)); // "오전 9:15"
  // CustomCommonUtil.formatTime12Hour("00:00"); // "오전 12:00"
  // CustomCommonUtil.formatTime12Hour("12:00"); // "오후 12:00"
  // ```
  static String formatTime12Hour(dynamic time) {
    int hour;
    int minute;

    if (time is String) {
      // "HH:MM" 형식 문자열 파싱
      final parts = time.split(':');
      hour = int.parse(parts[0]);
      minute = int.parse(parts[1]);
    } else if (time is TimeOfDay) {
      hour = time.hour;
      minute = time.minute;
    } else {
      throw ArgumentError('time은 String (HH:MM 형식) 또는 TimeOfDay여야 합니다.');
    }

    String period = hour < 12 ? '오전' : '오후';
    int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$period $displayHour:${minute.toString().padLeft(2, '0')}';
  }

  // 시간을 24시간 형식(HH:MM)으로 변환
  //
  // [time] 변환할 시간 (TimeOfDay)
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.formatTime(TimeOfDay(hour: 9, minute: 15)); // "09:15"
  // CustomCommonUtil.formatTime(TimeOfDay(hour: 14, minute: 30)); // "14:30"
  // CustomCommonUtil.formatTime(TimeOfDay(hour: 0, minute: 5)); // "00:05"
  // ```
  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  // 날짜가 오늘인지 확인
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isToday(DateTime.now()); // true
  // ```
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // 두 날짜 사이의 일수 차이 계산
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.daysBetween(DateTime(2024, 1, 1), DateTime(2024, 1, 5)); // 4
  // ```
  static int daysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  // 날짜에 일수 추가
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.addDays(DateTime.now(), 7); // 7일 후
  // ```
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  // 날짜에서 일수 빼기
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.subtractDays(DateTime.now(), 7); // 7일 전
  // ```
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  // 상대 시간 표시 ("방금 전", "5분 전", "3일 전" 등)
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.toRelativeTime(DateTime.now().subtract(Duration(minutes: 5))); // '5분 전'
  // CustomCommonUtil.toRelativeTime(DateTime.now().subtract(Duration(hours: 2))); // '2시간 전'
  // ```
  static String toRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years년 전';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  // ============================================
  // 문자열 관련 유틸리티 (StringUtil)
  // ============================================

  // 문자열이 비어있거나 null인지 확인
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isEmpty(null); // true
  // CustomCommonUtil.isEmpty(''); // true
  // CustomCommonUtil.isEmpty('   '); // true (trim 후)
  // ```
  static bool isEmpty(String? value, {bool trim = true}) {
    if (value == null) return true;
    return trim ? value.trim().isEmpty : value.isEmpty;
  }

  // 문자열이 비어있지 않은지 확인
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isNotEmpty('hello'); // true
  // ```
  static bool isNotEmpty(String? value, {bool trim = true}) {
    return !isEmpty(value, trim: trim);
  }

  // 문자열을 카멜케이스로 변환
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.toCamelCase('hello_world'); // 'helloWorld'
  // CustomCommonUtil.toCamelCase('hello-world'); // 'helloWorld'
  // ```
  static String toCamelCase(String value) {
    final words = value.split(RegExp(r'[_\s-]+'));
    if (words.isEmpty) return value;
    return words.first.toLowerCase() +
        words.skip(1).map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join();
  }

  // 문자열을 스네이크케이스로 변환
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.toSnakeCase('helloWorld'); // 'hello_world'
  // ```
  static String toSnakeCase(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  // 문자열을 지정된 길이로 자르고 말줄임표 추가
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.truncate('긴 텍스트입니다', maxLength: 5); // '긴 텍스트...'
  // ```
  static String truncate(
    String value, {
    required int maxLength,
    String ellipsis = '...',
  }) {
    if (value.length <= maxLength) return value;
    return value.substring(0, maxLength) + ellipsis;
  }

  // 숫자에 천단위 콤마 추가
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.formatNumberString('1234567'); // '1,234,567'
  // ```
  static String formatNumberString(String value) {
    try {
      final number = int.parse(value);
      return _addCommas(number.toString());
    } catch (e) {
      return value;
    }
  }

  // 숫자 문자열에 천단위 콤마 추가 (내부 헬퍼 함수)
  static String _addCommas(String numberStr) {
    // 소수점이 있는 경우 분리
    final parts = numberStr.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    // 음수 처리
    final isNegative = integerPart.startsWith('-');
    final absIntegerPart = isNegative ? integerPart.substring(1) : integerPart;

    // 뒤에서부터 3자리씩 나눠서 콤마 추가
    String result = '';
    for (int i = absIntegerPart.length - 1; i >= 0; i--) {
      if ((absIntegerPart.length - 1 - i) % 3 == 0 &&
          i != absIntegerPart.length - 1) {
        result = ',$result';
      }
      result = absIntegerPart[i] + result;
    }

    return (isNegative ? '-' : '') + result + decimalPart;
  }

  // 문자열에서 특정 문자 제거
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.removeChar('010-1234-5678', '-'); // '01012345678'
  // ```
  static String removeChar(String value, String char) {
    return value.replaceAll(char, '');
  }

  // 문자열에서 여러 문자 제거
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.removeChars('010-1234-5678', ['-', ' ']); // '01012345678'
  // ```
  static String removeChars(String value, List<String> chars) {
    String result = value;
    for (final char in chars) {
      result = result.replaceAll(char, '');
    }
    return result;
  }

  // ============================================
  // 검증 관련 유틸리티 (ValidationUtil)
  // ============================================

  // 이메일 형식 검증
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isEmail('test@example.com'); // true
  // CustomCommonUtil.isEmail('invalid'); // false
  // ```
  static bool isEmail(String value) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(value);
  }

  // 한국 전화번호 형식 검증 (010-1234-5678, 01012345678 등)
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isPhoneNumber('010-1234-5678'); // true
  // CustomCommonUtil.isPhoneNumber('01012345678'); // true
  // CustomCommonUtil.isPhoneNumber('02-1234-5678'); // true
  // ```
  static bool isPhoneNumber(String value) {
    // 하이픈 제거 후 검증
    final cleaned = removeChars(value, ['-', ' ', '(', ')']);
    final phoneRegex = RegExp(
      r'^(010|011|016|017|018|019|02|031|032|033|041|042|043|044|051|052|053|054|055|061|062|063|064)\d{7,8}$',
    );
    return phoneRegex.hasMatch(cleaned);
  }

  // URL 형식 검증
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isUrl('https://example.com'); // true
  // CustomCommonUtil.isUrl('http://example.com'); // true
  // CustomCommonUtil.isUrl('invalid'); // false
  // ```
  static bool isUrl(String value) {
    try {
      final uri = Uri.parse(value);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // 비밀번호 강도 검증
  // 반환값: 0 (약함), 1 (보통), 2 (강함), 3 (매우 강함)
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.validatePassword('password'); // 0 (약함)
  // CustomCommonUtil.validatePassword('Password123'); // 2 (강함)
  // CustomCommonUtil.validatePassword('P@ssw0rd!'); // 3 (매우 강함)
  // ```
  static int validatePassword(String password) {
    int strength = 0;

    // 길이 체크
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // 대문자 포함
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;

    // 소문자 포함
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;

    // 숫자 포함
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;

    // 특수문자 포함
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    // 최대 3점으로 제한
    if (strength <= 2) return 0; // 약함
    if (strength <= 4) return 1; // 보통
    if (strength <= 5) return 2; // 강함
    return 3; // 매우 강함
  }

  // 숫자만 포함하는지 검증
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isNumeric('123'); // true
  // CustomCommonUtil.isNumeric('12a'); // false
  // ```
  static bool isNumeric(String value) {
    return RegExp(r'^\d+$').hasMatch(value);
  }

  // 영문자만 포함하는지 검증
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isAlphabetic('abc'); // true
  // CustomCommonUtil.isAlphabetic('abc123'); // false
  // ```
  static bool isAlphabetic(String value) {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(value);
  }

  // 영문자와 숫자만 포함하는지 검증
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isAlphanumeric('abc123'); // true
  // CustomCommonUtil.isAlphanumeric('abc-123'); // false
  // ```
  static bool isAlphanumeric(String value) {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value);
  }

  // ============================================
  // 포맷팅 관련 유틸리티 (FormatUtil)
  // ============================================

  // 파일 크기를 읽기 쉬운 형식으로 포맷팅 (KB, MB, GB)
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.formatFileSize(1024); // '1.0 KB'
  // CustomCommonUtil.formatFileSize(1048576); // '1.0 MB'
  // CustomCommonUtil.formatFileSize(1073741824); // '1.0 GB'
  // ```
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Duration을 읽기 쉬운 형식으로 포맷팅 (분:초, 시간:분:초)
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.formatDuration(Duration(seconds: 125)); // '2:05'
  // CustomCommonUtil.formatDuration(Duration(hours: 2, minutes: 30, seconds: 45)); // '2:30:45'
  // ```
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  // 거리를 읽기 쉬운 형식으로 포맷팅 (미터 → km)
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.formatDistance(1500); // '1.5 km'
  // CustomCommonUtil.formatDistance(500); // '500 m'
  // ```
  static String formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // 가격을 원화 형식으로 포맷팅
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.formatPrice(10000); // '10,000원'
  // CustomCommonUtil.formatPrice(1000000); // '1,000,000원'
  // ```
  static String formatPrice(int price) {
    return '${_addCommas(price.toString())}원';
  }

  // 퍼센트를 포맷팅
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.formatPercent(0.25); // '25%'
  // CustomCommonUtil.formatPercent(0.1234, decimals: 2); // '12.34%'
  // ```
  static String formatPercent(double value, {int decimals = 0}) {
    final percent = value * 100;
    if (decimals == 0) {
      return '${percent.toInt()}%';
    } else {
      return '${percent.toStringAsFixed(decimals)}%';
    }
  }

  // ============================================
  // 숫자 관련 유틸리티 (NumberUtil)
  // ============================================

  // 숫자에 천단위 콤마 추가
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.formatNumber(1234567); // '1,234,567'
  // CustomCommonUtil.formatNumber(1234567.89); // '1,234,567.89'
  // CustomCommonUtil.formatNumber(1234567.89, decimals: 2); // '1,234,567.89'
  // ```
  static String formatNumber(num value, {int? decimals}) {
    if (decimals != null && value is double) {
      // 소수점 자리수 제한
      final formatted = value.toStringAsFixed(decimals);
      return _addCommas(formatted);
    } else if (value is double) {
      // 소수점이 있으면 그대로 표시
      return _addCommas(value.toString());
    } else {
      // 정수
      return _addCommas(value.toString());
    }
  }

  // 문자열을 안전하게 int로 변환 (실패 시 null 반환)
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.safeParseInt('123'); // 123
  // CustomCommonUtil.safeParseInt('abc'); // null
  // ```
  static int? safeParseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  // 문자열을 안전하게 double로 변환 (실패 시 null 반환)
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.safeParseDouble('123.45'); // 123.45
  // CustomCommonUtil.safeParseDouble('abc'); // null
  // ```
  static double? safeParseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  // 숫자가 양수인지 확인
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isPositive(5); // true
  // CustomCommonUtil.isPositive(-5); // false
  // ```
  static bool isPositive(num value) {
    return value > 0;
  }

  // 숫자가 음수인지 확인
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isNegative(-5); // true
  // CustomCommonUtil.isNegative(5); // false
  // ```
  static bool isNegative(num value) {
    return value < 0;
  }

  // 숫자가 범위 내에 있는지 확인
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.isInRange(5, min: 1, max: 10); // true
  // CustomCommonUtil.isInRange(15, min: 1, max: 10); // false
  // ```
  static bool isInRange(num value, {required num min, required num max}) {
    return value >= min && value <= max;
  }

  // 숫자를 원화 형식으로 포맷팅
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.formatCurrency(10000); // '10,000원'
  // ```
  static String formatCurrency(int value) {
    return formatPrice(value);
  }

  // 숫자를 퍼센트로 변환
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.toPercent(0.25); // '25%'
  // ```
  static String toPercent(double value, {int decimals = 0}) {
    return formatPercent(value, decimals: decimals);
  }

  // ============================================
  // Dialog 및 Snackbar 관련 유틸리티
  // ============================================

  // 성공 다이얼로그 표시
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.showSuccessDialog(
  //   context: context,
  //   title: '입력 결과',
  //   message: '성공적으로 추가되었습니다.',
  //   onConfirm: () {
  //     Navigator.of(context).pop(); // 다이얼로그 닫기
  //     Navigator.of(context).pop(true); // 화면 닫기
  //   },
  // );
  // ```
  static void showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'OK',
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  // 확인 다이얼로그 표시 (확인/취소 버튼)
  //
  // 사용 예시:
  // ```dart
  // final bool confirmed = await CustomCommonUtil.showConfirmDialog(
  //   context: context,
  //   title: '삭제 확인',
  //   message: '정말 삭제 하시겠습니까?',
  //   onConfirm: () async {
  //     await deleteItem();
  //   },
  // );
  // ```
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String confirmText = 'OK',
    String cancelText = 'Cancel',
    bool barrierDismissible = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                if (onConfirm != null) {
                  onConfirm();
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // 성공 스낵바 표시
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.showSuccessSnackbar(
  //   context: context,
  //   title: '삭제 결과',
  //   message: '목록이 성공적으로 삭제되었습니다.',
  // );
  // ```
  static void showSuccessSnackbar({
    required BuildContext context,
    required String title,
    required String message,
    Color backgroundColor = Colors.green,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 2),
  }) {
    _showTopBanner(
      context: context,
      title: title,
      message: message,
      backgroundColor: backgroundColor,
      textColor: textColor,
      duration: duration,
    );
  }

  // 에러 스낵바 표시
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.showErrorSnackbar(
  //   context: context,
  //   message: '입력시 문제가 발생 되었습니다.',
  // );
  // ```
  static void showErrorSnackbar({
    required BuildContext context,
    String title = 'Error',
    required String message,
    Color backgroundColor = Colors.red,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 2),
  }) {
    _showTopBanner(
      context: context,
      title: title,
      message: message,
      backgroundColor: backgroundColor,
      textColor: textColor,
      duration: duration,
    );
  }

  // 상단 스낵바 형태로 MaterialBanner 표시
  static void _showTopBanner({
    required BuildContext context,
    required String title,
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        content: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$title  ',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              TextSpan(
                text: message,
                style: TextStyle(color: textColor),
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: Text('닫기', style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );

    Future<void>.delayed(duration, () {
      messenger.hideCurrentMaterialBanner();
    });
  }

  // 로딩 오버레이 표시 (다이얼로그처럼 사용)
  // 전체 화면을 차단하고 로딩 인디케이터를 표시합니다
  //
  // 사용 예시:
  // ```dart
  // // 로딩 시작
  // CustomCommonUtil.showLoadingOverlay(context);
  //
  // try {
  //   await someAsyncOperation();
  // } finally {
  //   // 로딩 종료
  //   CustomCommonUtil.hideLoadingOverlay(context);
  // }
  // ```
  static void showLoadingOverlay(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false, // 배경 터치로 닫을 수 없음
      barrierColor: Colors.black.withOpacity(0.5), // 반투명 배경
      useRootNavigator: true, // root navigator 사용 (뒤로가기 시 기본 화면으로 가지 않도록)
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false, // 뒤로가기로 닫을 수 없음
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 로딩 오버레이 숨기기
  static void hideLoadingOverlay(BuildContext context) {
    // canPop을 체크하여 다이얼로그가 있는 경우에만 pop
    // 이미 닫혔거나 pop할 수 없는 경우 상위 화면이 닫히지 않도록 방지
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  // 디버깅을 위한 오류 정보 출력 함수
  //
  // 사용 예시:
  // ```dart
  // CustomCommonUtil.logError(
  //   functionName: '_deleteTodoList',
  //   error: e,
  //   statusCode: response.statusCode,
  //   responseData: data,
  // );
  // ```
  static void logError({
    required String functionName,
    Object? error,
    int? statusCode,
    dynamic responseData,
    String? url,
    Map<String, dynamic>? requestBody,
  }) {
    print('═══════════════════════════════════════════════════════');
    print('🚨 [ERROR] 함수: $functionName');
    print('═══════════════════════════════════════════════════════');

    if (url != null) {
      print('📍 URL: $url');
    }

    if (requestBody != null) {
      print('📤 요청 본문: $requestBody');
    }

    if (statusCode != null) {
      print('📊 상태 코드: $statusCode');
    }

    if (responseData != null) {
      print('📥 응답 데이터: $responseData');
    }

    if (error != null) {
      print('❌ 오류: $error');
      if (error is Error) {
        print('📚 스택 트레이스: ${error.stackTrace}');
      }
    }

    print('═══════════════════════════════════════════════════════');
  }
}
