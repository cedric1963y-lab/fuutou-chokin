import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuutou_chokin/app.dart';
import 'package:fuutou_chokin/domain/ledger.dart';
import 'package:fuutou_chokin/domain/payday.dart';
import 'package:fuutou_chokin/monetization/ad_service.dart';
import 'package:fuutou_chokin/persistence/ledger_repository.dart';
import 'package:fuutou_chokin/premium/premium_nudge.dart';
import 'package:fuutou_chokin/premium/premium_store.dart';
import 'package:fuutou_chokin/state/ledger_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 12, 1);
  test('出す条件', () {
    bool f({int s = 5, int l = 3, int d = 0, int? at}) => PremiumNudge.shouldShow(
        now: now, spends: s, launches: l, dismissCount: d, dismissedAtMs: at);
    expect(f(), isTrue);
    expect(f(s: 4), isFalse);
    expect(f(l: 2), isFalse);
    expect(f(d: 3), isFalse);
    expect(f(d: 1, at: now.subtract(const Duration(days: 13)).millisecondsSinceEpoch), isFalse);
    expect(f(d: 1, at: now.subtract(const Duration(days: 14)).millisecondsSinceEpoch), isTrue);
  });

  Future<LedgerController> ledger() async {
    final c = LedgerController(MemoryLedgerRepository(), clock: () => DateTime(2026, 10, 19));
    await c.load();
    await c.finishSetup(
      rule: const PaydayRule(day: 25),
      picks: starterEnvelopes.where((e) => e.onByDefault).toList(),
    );
    return c;
  }

  Widget app(LedgerController c, PremiumStore p) =>
      FuutouApp(controller: c, ads: AdService(enabled: false), premium: p);

  testWidgets('使い込んだ人にだけカードが出て、閉じると出なくなる', (tester) async {
    SharedPreferences.setMockInitialValues({
      PremiumNudge.kSpendCount: 6,
      PremiumNudge.kLaunches: 4,
    });
    final c = await ledger();
    await tester.pumpWidget(app(c, PremiumStore(enabled: false)));
    await tester.pumpAndSettle();
    expect(find.text('広告なしで、もっと便利に'), findsOneWidget);
    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('広告なしで、もっと便利に'), findsNothing);
    final p = await SharedPreferences.getInstance();
    expect(p.getInt(PremiumNudge.kDismissCount), 1);
  });

  testWidgets('使い始めたばかり・購入済みでは出ない', (tester) async {
    SharedPreferences.setMockInitialValues({PremiumNudge.kSpendCount: 1, PremiumNudge.kLaunches: 1});
    final c = await ledger();
    await tester.pumpWidget(app(c, PremiumStore(enabled: false)));
    await tester.pumpAndSettle();
    expect(find.text('広告なしで、もっと便利に'), findsNothing);

    SharedPreferences.setMockInitialValues({PremiumNudge.kSpendCount: 9, PremiumNudge.kLaunches: 9});
    final c2 = await ledger();
    await tester.pumpWidget(app(c2, PremiumStore(enabled: false, unlocked: true)));
    await tester.pumpAndSettle();
    expect(find.text('広告なしで、もっと便利に'), findsNothing);
  });
}
