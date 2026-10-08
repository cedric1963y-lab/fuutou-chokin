import 'jp_holidays.dart';
import 'yen.dart';

/// 給料日の決め方。[day] は 1〜31（31 は「月末」として扱う）。
class PaydayRule {
  const PaydayRule({this.day = 25, this.shiftBeforeRestDay = true});

  final int day;

  /// 土日祝なら前の平日に繰り上げる。
  final bool shiftBeforeRestDay;

  PaydayRule copyWith({int? day, bool? shiftBeforeRestDay}) => PaydayRule(
        day: day ?? this.day,
        shiftBeforeRestDay: shiftBeforeRestDay ?? this.shiftBeforeRestDay,
      );

  String get label => day >= 31 ? '毎月末日' : '毎月$day日';

  /// その月の実際の給料日。
  DateTime inMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    var d = DateTime(first.year, first.month, day > lastDay ? lastDay : day);
    if (shiftBeforeRestDay) {
      while (JpHolidays.isRestDay(d)) {
        d = d.subtract(const Duration(days: 1));
      }
    }
    return d;
  }

  /// [after] より後の最初の給料日。
  DateTime nextAfter(DateTime after) {
    final a = dateOnly(after);
    for (var i = 0; i < 4; i++) {
      final p = inMonth(a.year, a.month + i);
      if (p.isAfter(a)) return p;
    }
    return inMonth(a.year, a.month + 4);
  }

  /// [on] 以前で最も近い給料日。
  DateTime latestOnOrBefore(DateTime on) {
    final a = dateOnly(on);
    for (var i = 0; i < 4; i++) {
      final p = inMonth(a.year, a.month - i);
      if (!p.isAfter(a)) return p;
    }
    return inMonth(a.year, a.month - 4);
  }

  Map<String, Object> toJson() => {'day': day, 'shift': shiftBeforeRestDay};

  static PaydayRule fromJson(Map<String, dynamic>? j) => j == null
      ? const PaydayRule()
      : PaydayRule(
          day: (j['day'] as num?)?.toInt() ?? 25,
          shiftBeforeRestDay: j['shift'] as bool? ?? true,
        );
}
