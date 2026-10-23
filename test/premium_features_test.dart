import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fuutou_chokin/domain/csv_export.dart';
import 'package:fuutou_chokin/domain/goals.dart';
import 'package:fuutou_chokin/domain/ledger.dart';
import 'package:fuutou_chokin/domain/payday.dart';
import 'package:fuutou_chokin/domain/trend.dart';

Ledger _ledger() => Ledger(
      envelopes: [
        Envelope(id: 'food', name: '食費', budget: 30000),
        Envelope(id: 'fun', name: '娯楽', budget: 10000),
        Envelope(id: 'savings', name: '貯金', budget: 20000, isSavings: true, carried: 50000),
      ],
      spends: [
        Spend(id: '1', envelopeId: 'food', amount: 26000, on: DateTime(2026, 10, 1), memo: 'スーパー, まとめ買い'),
        Spend(id: '2', envelopeId: 'fun', amount: 4000, on: DateTime(2026, 10, 2)),
      ],
      periodStart: DateTime(2026, 9, 25),
      rule: const PaydayRule(day: 25),
      history: [],
    );

void main() {
  test('目標は貯金の合計を上から順にあてる', () {
    final goals = [
      SavingsGoal(id: 'a', name: '旅行', target: 100000),
      SavingsGoal(id: 'b', name: '車検', target: 80000),
    ];
    final p = fillGoals(goals, 130000);
    expect(p[0].reached, isTrue);
    expect(p[0].remaining, 0);
    expect(p[1].covered, 30000);
    expect(p[1].remaining, 50000);
    expect(fillGoals(goals, -500).first.covered, 0);
  });

  test('目標は保存して読み直せる。古いデータ（目標なし）も読める', () {
    final l = _ledger()..goals.add(SavingsGoal(id: 'a', name: '旅行', target: 100000, memo: '夏'));
    final again = Ledger.fromJson(jsonDecode(jsonEncode(l.toJson())) as Map<String, dynamic>);
    expect(again.goals.single.name, '旅行');
    expect(again.goals.single.memo, '夏');
    final old = l.toJson()..remove('goals');
    expect(Ledger.fromJson(jsonDecode(jsonEncode(old)) as Map<String, dynamic>).goals, isEmpty);
  });

  test('期間ごとの推移（締めた期間＋今の期間）', () {
    final l = _ledger();
    l.closePeriod({'food': Leftover.save, 'fun': Leftover.carry}, DateTime(2026, 10, 23));
    l.spends.add(Spend(id: '3', envelopeId: 'food', amount: 5000, on: DateTime(2026, 10, 24)));
    final all = spendingTrend(l);
    expect(all.length, 2);
    expect(all.first.spent, 30000);
    expect(all.first.budget, 40000);
    expect(all.last.current, isTrue);
    expect(all.last.spent, 5000);
    final food = spendingTrend(l, envelopeName: '食費');
    expect(food.first.spent, 26000);
    expect(trendEnvelopeNames(l), ['食費', '娯楽']);
  });

  test('CSVは BOM つき、カンマ入りのメモはくくる', () {
    final l = _ledger();
    l.closePeriod({'food': Leftover.save, 'fun': Leftover.carry}, DateTime(2026, 10, 23));
    l.spends.add(Spend(id: '3', envelopeId: 'fun', amount: 1200, on: DateTime(2026, 10, 24), memo: '映画'));
    final csv = spendsCsv(l);
    expect(csv.startsWith('\uFEFF日付,封筒,金額,メモ,期間'), isTrue);
    expect(csv, contains('2026-10-01,食費,26000,"スーパー, まとめ買い",2026-09-25〜2026-10-22'));
    expect(csv, contains('2026-10-24,娯楽,1200,映画,2026-10-23〜（今の期間）'));
    final periods = periodsCsv(l);
    expect(periods, contains('2026-09-25,2026-10-22,食費,30000,0,26000,4000,貯金へ'));
    expect(periods, contains('貯金の袋'));
  });
}
