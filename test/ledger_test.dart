import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fuutou_chokin/domain/ledger.dart';
import 'package:fuutou_chokin/domain/payday.dart';

Ledger _ledger() => Ledger(
      envelopes: [
        Envelope(id: 'food', name: '食費', budget: 30000),
        Envelope(id: 'fun', name: '娯楽', budget: 10000, carried: 1000),
        Envelope(id: 'out', name: '外食', budget: 5000),
        Envelope(id: 'savings', name: '貯金', budget: 20000, isSavings: true, carried: 50000),
      ],
      spends: [
        Spend(id: '1', envelopeId: 'food', amount: 26000, on: DateTime(2026, 10, 1)),
        Spend(id: '2', envelopeId: 'fun', amount: 4000, on: DateTime(2026, 10, 2)),
        Spend(id: '3', envelopeId: 'out', amount: 6500, on: DateTime(2026, 10, 3)),
      ],
      periodStart: DateTime(2026, 9, 25),
      rule: const PaydayRule(day: 25),
      history: [],
    );

void main() {
  test('残りの計算', () {
    final l = _ledger();
    expect(l.balanceOf(l.byId('food')!), 4000);
    expect(l.balanceOf(l.byId('fun')!), 7000);
    expect(l.balanceOf(l.byId('out')!), -1500);
    expect(l.spendableLeft, 9500);
    expect(l.totalSaved, 70000);
    expect(l.isPaydayDue(DateTime(2026, 10, 22)), isFalse);
    expect(l.isPaydayDue(DateTime(2026, 10, 23)), isTrue);
    expect(l.daysUntilPayday(DateTime(2026, 10, 19)), 4);
  });

  test('給料日の締め: 繰越と貯金へ', () {
    final l = _ledger();
    final choices = {'food': Leftover.save, 'fun': Leftover.carry, 'out': Leftover.clear};
    expect(l.movedBy(choices), 4000);
    final closed = l.closePeriod(choices, DateTime(2026, 10, 23));
    expect(closed.movedToSavings, 4000);
    expect(closed.end, DateTime(2026, 10, 22));
    expect(l.spends, isEmpty);
    expect(l.periodStart, DateTime(2026, 10, 23));
    expect(l.byId('food')!.carried, 0);
    expect(l.byId('fun')!.carried, 7000);
    expect(l.byId('out')!.carried, 0);
    // 貯金: 50000 + 20000 + 4000 を持ち越し、今期の 20000 が入る
    expect(l.byId('savings')!.carried, 74000);
    expect(l.totalSaved, 94000);
    expect(l.movedToSavingsAllTime, 4000);
    expect(l.history.single.results.length, 4);
  });

  test('マイナスの繰越と、マイナスは貯金へ移せない', () {
    final l = _ledger();
    l.closePeriod({'out': Leftover.save}, DateTime(2026, 10, 23));
    expect(l.byId('out')!.carried, -1500);
    expect(l.history.first.movedToSavings, 0);
  });

  test('JSON で保存して読み戻せる', () {
    final l = _ledger();
    l.closePeriod(l.defaultChoices(), DateTime(2026, 10, 23));
    final back = Ledger.fromJson(
        jsonDecode(jsonEncode(l.toJson())) as Map<String, dynamic>);
    expect(back.envelopes.length, 4);
    expect(back.totalSaved, l.totalSaved);
    expect(back.history.single.spends.length, 3);
    expect(back.rule.day, 25);
  });
}
