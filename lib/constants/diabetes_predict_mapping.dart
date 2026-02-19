// 라디오 인덱스 → API 전송용 실제값 변환

class BloodGlucoseMapping {
  static const List<(int, int)> ranges = [
    (44, 98),   // 0: min ~ 25%
    (99, 116),  // 1: 25% ~ 50%
    (117, 139), // 2: 50% ~ 75%
    (140, 199), // 3: 75% ~ max
  ];

  static double toValue(int index) {
    final r = ranges[index.clamp(0, ranges.length - 1)];
    return (r.$1 + r.$2) / 2;
  }

  static (int, int) toRange(int index) =>
      ranges[index.clamp(0, ranges.length - 1)];
}

class PregnancyMapping {
  static const List<(int, int)> ranges = [
    (0, 0),   // 0: min ~ 25% (0만)
    (1, 2),   // 1: 25% ~ 50%
    (3, 5),   // 2: 50% ~ 75%
    (6, 14),  // 3: 75% ~ max
  ];

  static double toValue(int index) {
    final r = ranges[index.clamp(0, ranges.length - 1)];
    return (r.$1 + r.$2) / 2;
  }

  static (int, int) toRange(int index) =>
      ranges[index.clamp(0, ranges.length - 1)];
}
