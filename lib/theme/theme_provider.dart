import 'package:flutter/material.dart';

/// 테마 정보를 제공하는 InheritedWidget
class ThemeProvider extends InheritedWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const ThemeProvider({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required super.child,
  });

  /// 현재 테마 정보에 접근하는 static 메서드
  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  /// InheritedWidget 업데이트 여부 확인
  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}

/// BuildContext extension - context.themeMode, context.toggleTheme 사용 가능
extension ThemeContext on BuildContext {
  /// 현재 테마 모드 가져오기
  ThemeMode get themeMode {
    final provider = ThemeProvider.of(this);
    return provider?.themeMode ?? ThemeMode.system;
  }

  /// 테마 토글하기
  void toggleTheme() {
    final provider = ThemeProvider.of(this);
    provider?.onToggleTheme();
  }

  /// 다크 모드인지 확인
  bool get isDarkMode {
    final currentTheme = themeMode;
    if (currentTheme == ThemeMode.dark) return true;
    if (currentTheme == ThemeMode.light) return false;
    // ThemeMode.system인 경우 시스템 설정 확인
    return MediaQuery.of(this).platformBrightness == Brightness.dark;
  }
}

