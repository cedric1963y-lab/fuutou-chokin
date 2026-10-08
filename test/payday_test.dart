import 'package:flutter_test/flutter_test.dart';
import 'package:fuutou_chokin/domain/jp_holidays.dart';
import 'package:fuutou_chokin/domain/payday.dart';

void main() {
  test('2026年の祝日（振替休日・国民の休日を含む）', () {
    for (final d in [
      DateTime(2026, 1, 1), DateTime(2026, 1, 12), DateTime(2026, 2, 11),
      DateTime(2026, 2, 23), DateTime(2026, 3, 20), DateTime(2026, 4, 29),
      DateTime(2026, 5, 3), DateTime(2026, 5, 4), DateTime(2026, 5, 5),
      DateTime(2026, 5, 6), DateTime(2026, 7, 20), DateTime(2026, 8, 11),
      DateTime(2026, 9, 21), DateTime(2026, 9, 22), DateTime(2026, 9, 23),
      DateTime(2026, 10, 12), DateTime(2026, 11, 3), DateTime(2026, 11, 23),
    ]) {
      expect(JpHolidays.isHoliday(d), isTrue, reason: '$d');
    }
    expect(JpHolidays.isHoliday(DateTime(2026, 5, 7)), isFalse);
    expect(JpHolidays.isHoliday(DateTime(2026, 9, 24)), isFalse);
    expect(JpHolidays.isHoliday(DateTime(2027, 3, 21)), isTrue);
    expect(JpHolidays.isHoliday(DateTime(2027, 3, 22)), isTrue); // 振替
  });

  test('25日払い・土日祝は前の平日', () {
    const rule = PaydayRule(day: 25);
    expect(rule.inMonth(2026, 10), DateTime(2026, 10, 23)); // 25日は日曜
    expect(rule.inMonth(2026, 7), DateTime(2026, 7, 24)); // 25日は土曜
    expect(rule.inMonth(2026, 8), DateTime(2026, 8, 25));
    const noShift = PaydayRule(day: 25, shiftBeforeRestDay: false);
    expect(noShift.inMonth(2026, 10), DateTime(2026, 10, 25));
  });

  test('祝日をまたいで繰り上げ', () {
    const rule = PaydayRule(day: 23);
    // 2026/9/23 秋分の日(水) → 22 国民の休日 → 21 敬老の日 → 20 日 → 19 土 → 18 金
    expect(rule.inMonth(2026, 9), DateTime(2026, 9, 18));
  });

  test('月末払い', () {
    const rule = PaydayRule(day: 31);
    expect(rule.inMonth(2026, 2), DateTime(2026, 2, 27)); // 28日は土曜
    expect(rule.inMonth(2026, 4), DateTime(2026, 4, 30));
    expect(rule.inMonth(2026, 1), DateTime(2026, 1, 30)); // 31日は土曜
  });

  test('次の給料日・直近の給料日', () {
    const rule = PaydayRule(day: 25);
    expect(rule.nextAfter(DateTime(2026, 9, 25)), DateTime(2026, 10, 23));
    expect(rule.nextAfter(DateTime(2026, 10, 23)), DateTime(2026, 11, 25));
    expect(rule.latestOnOrBefore(DateTime(2026, 10, 22)), DateTime(2026, 9, 25));
    expect(rule.latestOnOrBefore(DateTime(2026, 10, 23)), DateTime(2026, 10, 23));
    expect(rule.nextAfter(DateTime(2026, 12, 28)), DateTime(2027, 1, 25));
  });
}
