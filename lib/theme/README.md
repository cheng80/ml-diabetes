# Theme 폴더 사용 가이드

테마 모드 관리와 앱 전용 색상을 제공합니다. `material.dart`만 의존하며, 커스텀 스키마 없이 단순하게 구성되어 있습니다.

---

## 폴더 구조

```
lib/theme/
  theme_provider.dart    # 테마 모드(light/dark) 상태 관리
  app_theme_colors.dart # Brightness 기반 앱 색상 (샘플)
  README.md             # 사용 문서
```

---

## 1. ThemeProvider

테마 모드(라이트/다크) 상태를 관리하는 InheritedWidget입니다.

### 1.1 설정 (main.dart)

```dart
import 'theme/theme_provider.dart';

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      themeMode: _themeMode,
      onToggleTheme: _toggleTheme,
      child: MaterialApp(
        theme: ThemeData(...),
        darkTheme: ThemeData(...),
        themeMode: _themeMode,
        home: HomePage(),
      ),
    );
  }
}
```

### 1.2 사용

```dart
import 'theme/theme_provider.dart';

// 테마 모드 가져오기
final mode = context.themeMode;  // ThemeMode.light | .dark | .system

// 테마 토글
context.toggleTheme();

// 다크 모드 여부
if (context.isDarkMode) {
  // 다크 모드 UI
}
```

### 1.3 ThemeMode

| 값 | 설명 |
|----|------|
| `ThemeMode.light` | 항상 라이트 |
| `ThemeMode.dark` | 항상 다크 |
| `ThemeMode.system` | 시스템 설정 따름 |

---

## 2. AppThemeColors

`Theme.of(context).brightness`로 라이트/다크를 판별해 색상을 반환합니다. ThemeExtension 없이 단순 구현입니다.

### 2.1 Import

```dart
import 'theme/app_theme_colors.dart';
```

### 2.2 사용 방법

**방법 A: static 메서드**

```dart
Container(color: AppThemeColors.background(context))
Text('제목', style: TextStyle(color: AppThemeColors.textPrimary(context)))
```

**방법 B: extension (context.appTheme)**

```dart
final p = context.appTheme;
Container(color: p.background)
Text('제목', style: TextStyle(color: p.textPrimary))
```

### 2.3 제공 색상

| 메서드 | 설명 |
|--------|------|
| `background` | 전체 배경 |
| `cardBackground` | 카드/패널 배경 |
| `primary` | 주요 포인트 |
| `accent` | 보조 포인트 |
| `textPrimary` | 기본 텍스트 |
| `textSecondary` | 보조 텍스트 |
| `textOnPrimary` | Primary 배경 위 텍스트 |
| `divider` | 구분선 |
| `chipSelectedBg` | 칩 선택 배경 |
| `chipSelectedText` | 칩 선택 텍스트 |
| `chipUnselectedBg` | 칩 비선택 배경 |
| `chipUnselectedText` | 칩 비선택 텍스트 |

### 2.4 ThemeData 정의용 상수

`MaterialApp`의 `theme`/`darkTheme`에서 사용할 때는 `BuildContext`가 없으므로 상수를 사용합니다.

```dart
MaterialApp(
  theme: ThemeData(
    scaffoldBackgroundColor: AppThemeColors.lightBackground,
  ),
  darkTheme: ThemeData(
    scaffoldBackgroundColor: AppThemeColors.darkBackground,
  ),
  ...
)
```

| 상수 | 설명 |
|------|------|
| `AppThemeColors.lightBackground` | 라이트 배경 |
| `AppThemeColors.darkBackground` | 다크 배경 |

---

## 3. 앱별 커스터마이징

### 3.1 색상 변경

`app_theme_colors.dart`의 각 메서드 내부 색상 값을 앱에 맞게 수정합니다.

```dart
static Color primary(BuildContext context) =>
    _isDark(context)
        ? const Color(0xFF90CAF9)  // 다크용 - 원하는 색으로 변경
        : const Color(0xFF1976D2); // 라이트용 - 원하는 색으로 변경
```

### 3.2 색상 추가

새 semantic 색이 필요하면 `AppThemeColors`에 static 메서드를 추가합니다.

```dart
/// 시트 배경 색
static Color sheetBackground(BuildContext context) =>
    _isDark(context)
        ? const Color(0xFF2C2C2C)
        : Colors.white;
```

`AppThemeColorsHelper`에도 getter를 추가합니다.

```dart
Color get sheetBackground => AppThemeColors.sheetBackground(_context);
```

---

## 4. Custom 위젯과의 관계

- **Custom 위젯** (`lib/custom/`): `Theme.of(context).colorScheme` 기반 (`CustomThemeHelper`)
- **앱 페이지**: `AppThemeColors` 또는 `Theme.of(context).colorScheme` 사용

Custom 위젯은 theme 폴더에 의존하지 않으므로, 다른 앱에서 `lib/custom/`만 복사해 사용할 수 있습니다.

---

## 5. 다른 앱에서 사용 시

- **ThemeProvider**: `theme_provider.dart`만 복사하면 됨 (material.dart만 의존)
- **AppThemeColors**: 앱별로 색상을 정의하므로, `app_theme_colors.dart`를 참고해 새 앱에 맞게 작성
