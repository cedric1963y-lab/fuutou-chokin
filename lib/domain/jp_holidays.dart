/// 日本の祝日（2007年以降の祝日法ベース。振替休日・国民の休日を含む）。
/// 給料日を「前の平日」にずらす判定だけに使う。
class JpHolidays {
  JpHolidays._();

  static final Map<int, Set<int>> _cache = {};

  static bool isHoliday(DateTime day) {
    final set = _cache.putIfAbsent(day.year, () => _build(day.year));
    return set.contains(_key(day.month, day.day));
  }

  static bool isRestDay(DateTime day) =>
      day.weekday == DateTime.saturday ||
      day.weekday == DateTime.sunday ||
      isHoliday(day);

  static int _key(int m, int d) => m * 100 + d;

  static int _nthMonday(int y, int m, int n) {
    final first = DateTime(y, m, 1);
    final offset = (DateTime.monday - first.weekday + 7) % 7;
    return 1 + offset + (n - 1) * 7;
  }

  static int _vernal(int y) =>
      (20.8431 + 0.242194 * (y - 1980) - ((y - 1980) ~/ 4)).floor();

  static int _autumnal(int y) =>
      (23.2488 + 0.242194 * (y - 1980) - ((y - 1980) ~/ 4)).floor();

  static Set<int> _build(int y) {
    final base = <DateTime>[
      DateTime(y, 1, 1),
      DateTime(y, 1, _nthMonday(y, 1, 2)),
      DateTime(y, 2, 11),
      if (y >= 2020) DateTime(y, 2, 23),
      if (y <= 2018) DateTime(y, 12, 23),
      DateTime(y, 3, _vernal(y)),
      DateTime(y, 4, 29),
      DateTime(y, 5, 3),
      DateTime(y, 5, 4),
      DateTime(y, 5, 5),
      if (y == 2020)
        DateTime(y, 7, 23)
      else if (y == 2021)
        DateTime(y, 7, 22)
      else
        DateTime(y, 7, _nthMonday(y, 7, 3)),
      if (y == 2020)
        DateTime(y, 8, 10)
      else if (y == 2021)
        DateTime(y, 8, 8)
      else if (y >= 2016)
        DateTime(y, 8, 11),
      DateTime(y, 9, _nthMonday(y, 9, 3)),
      DateTime(y, 9, _autumnal(y)),
      if (y == 2020)
        DateTime(y, 7, 24)
      else if (y == 2021)
        DateTime(y, 7, 23)
      else
        DateTime(y, 10, _nthMonday(y, 10, 2)),
      DateTime(y, 11, 3),
      DateTime(y, 11, 23),
    ];
    final keys = base.map((d) => _key(d.month, d.day)).toSet();
    bool has(DateTime d) => d.year == y && keys.contains(_key(d.month, d.day));

    // 国民の休日: 祝日に挟まれた平日
    for (final d in base) {
      final next = d.add(const Duration(days: 1));
      final after = d.add(const Duration(days: 2));
      if (!has(next) && has(after) && next.weekday != DateTime.sunday) {
        keys.add(_key(next.month, next.day));
      }
    }
    // 振替休日: 日曜の祝日のあと、最初の祝日でない日
    for (final d in base) {
      if (d.weekday != DateTime.sunday) continue;
      var sub = d.add(const Duration(days: 1));
      while (has(sub)) {
        sub = sub.add(const Duration(days: 1));
      }
      if (sub.year == y) keys.add(_key(sub.month, sub.day));
    }
    return keys;
  }
}
