import 'package:flutter_test/flutter_test.dart';
import 'package:fuutou_chokin/domain/ledger.dart';
import 'package:fuutou_chokin/domain/payday.dart';
import 'package:fuutou_chokin/domain/yen.dart';

/// HomeWidgetSync.publish と同じ行形式（プラグインなしで検証）。
List<Map<String, Object?>> rowsFor(Ledger ledger) {
  return ledger.envelopes.map((e) {
    final left = ledger.balanceOf(e);
    final funded = e.isSavings ? e.budget : ledger.fundedIn(e);
    return {
      'id': e.id,
      'name': e.name,
      'tint': e.tint.index,
      'left': left,
      'funded': funded,
      'savings': e.isSavings,
      'leftLabel': yen(left),
    };
  }).toList();
}

void main() {
  test('ウィジェット用 JSON 行に名前と残高が入る', () {
    final food = Envelope(id: 'food', name: '食費', budget: 32000);
    final savings = Envelope(
      id: 'savings',
      name: '貯金',
      budget: 20000,
      isSavings: true,
      carried: 5000,
    );
    final ledger = Ledger(
      envelopes: [food, savings],
      spends: [
        Spend(id: 's1', envelopeId: 'food', amount: 1200, on: DateTime(2026, 10, 1)),
      ],
      periodStart: DateTime(2026, 9, 25),
      rule: const PaydayRule(day: 25),
      history: const [],
    );
    final rows = rowsFor(ledger);
    expect(rows.length, 2);
    expect(rows.first['name'], '食費');
    expect(rows.first['left'], 32000 - 1200);
    expect(rows.first['leftLabel'], yen(30800));
    expect(rows.last['name'], '貯金');
    expect(rows.last['savings'], true);
    expect(rows.last['left'], 25000); // carried 5000 + budget 20000
  });
}
