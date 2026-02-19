import 'package:flutter/material.dart';

/// 앱 전용 테마 색상 (Brightness 기반)
///
/// Theme.of(context).brightness로 라이트/다크 판별.
/// ThemeExtension 없이 단순 구현.
///
/// 사용 예시:
/// ```dart
/// Container(color: AppThemeColors.background(context))
/// Text('제목', style: TextStyle(color: AppThemeColors.textPrimary(context)))
/// ```
class AppThemeColors {
  AppThemeColors._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ThemeData 정의용 상수 (main.dart 등에서 사용)
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color darkBackground = Color(0xFF121212);

  /// 전체 배경 색
  static Color background(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5);

  /// 카드/패널 배경 색
  static Color cardBackground(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFF1E1E1E)
          : Colors.white;

  /// 주요 포인트 색
  static Color primary(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFF90CAF9)
          : const Color(0xFF1976D2);

  /// 보조 포인트 색
  static Color accent(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFFFFB74D)
          : const Color(0xFFFF9800);

  /// 기본 텍스트 색
  static Color textPrimary(BuildContext context) =>
      _isDark(context)
          ? Colors.white
          : const Color(0xFF212121);

  /// 보조 텍스트 색
  static Color textSecondary(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFFB0B0B0)
          : const Color(0xFF757575);

  /// Primary 배경 위 텍스트 색
  static Color textOnPrimary(BuildContext context) =>
      Colors.white;

  /// 구분선 색
  static Color divider(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFF424242)
          : const Color(0xFFE0E0E0);

  /// 칩 선택 배경 색
  static Color chipSelectedBg(BuildContext context) =>
      primary(context);

  /// 칩 선택 텍스트 색
  static Color chipSelectedText(BuildContext context) =>
      textOnPrimary(context);

  /// 칩 비선택 배경 색
  static Color chipUnselectedBg(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFE3F2FD);

  /// 칩 비선택 텍스트 색
  static Color chipUnselectedText(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFFB0BEC5)
          : const Color(0xFF1565C0);
}

/// BuildContext 확장 - context.appTheme.xxx 로 접근
extension AppThemeContext on BuildContext {
  AppThemeColorsHelper get appTheme => AppThemeColorsHelper(this);
}

/// context.appTheme 접근용 헬퍼
class AppThemeColorsHelper {
  final BuildContext _context;

  AppThemeColorsHelper(this._context);

  Color get background => AppThemeColors.background(_context);
  Color get cardBackground => AppThemeColors.cardBackground(_context);
  Color get primary => AppThemeColors.primary(_context);
  Color get accent => AppThemeColors.accent(_context);
  Color get textPrimary => AppThemeColors.textPrimary(_context);
  Color get textSecondary => AppThemeColors.textSecondary(_context);
  Color get textOnPrimary => AppThemeColors.textOnPrimary(_context);
  Color get divider => AppThemeColors.divider(_context);
  Color get chipSelectedBg => AppThemeColors.chipSelectedBg(_context);
  Color get chipSelectedText => AppThemeColors.chipSelectedText(_context);
  Color get chipUnselectedBg => AppThemeColors.chipUnselectedBg(_context);
  Color get chipUnselectedText => AppThemeColors.chipUnselectedText(_context);
}
