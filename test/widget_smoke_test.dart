import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuutou_chokin/domain/ledger.dart';
import 'package:fuutou_chokin/domain/payday.dart';
import 'package:fuutou_chokin/app.dart';
import 'package:fuutou_chokin/monetization/ad_service.dart';
import 'package:fuutou_chokin/persistence/ledger_repository.dart';
import 'package:fuutou_chokin/premium/premium_screen.dart';
import 'package:fuutou_chokin/premium/premium_store.dart';
import 'package:fuutou_chokin/state/ledger_controller.dart';

void main() {
  testWidgets('はじめての設定から封筒の一覧まで', (tester) async {
    final c = LedgerController(MemoryLedgerRepository(), clock: () => DateTime(2026, 10, 19));
    await c.load();
    await tester.pumpWidget(FuutouApp(
        controller: c, ads: AdService(enabled: false), premium: PremiumStore(enabled: false)));
    await tester.pumpAndSettle();
    expect(find.text('封筒貯金へようこそ'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('袋分けをはじめる'), 200);
    await tester.tap(find.text('袋分けをはじめる'));
    await tester.pumpAndSettle();
    expect(find.text('支出を記録'), findsOneWidget);
    expect(find.text('食費'), findsWidgets);
    expect(c.ledger.periodStart, DateTime(2026, 9, 25));
  });

  testWidgets('購入前はプレミアムの機能が案内になり、今ある画面はそのまま', (tester) async {
    final c = LedgerController(MemoryLedgerRepository(), clock: () => DateTime(2026, 10, 19));
    await c.load();
    await c.finishSetup(rule: const PaydayRule(day: 25), picks: starterEnvelopes.where((e) => e.onByDefault).toList());
    await tester.pumpWidget(FuutouApp(
        controller: c, ads: AdService(enabled: false), premium: PremiumStore(enabled: false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('貯金と履歴').last);
    await tester.pumpAndSettle();
    expect(find.text('貯金の目標'), findsOneWidget);
    expect(find.text('月ごとのグラフ'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
    await tester.tap(find.text('月ごとのグラフ'));
    await tester.pumpAndSettle();
    expect(find.text('封筒貯金 プレミアム'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('購入を復元'), 200,
        scrollable: find.descendant(of: find.byType(PremiumScreen), matching: find.byType(Scrollable)).first);
    expect(find.text('購入を復元'), findsOneWidget);
  });

  testWidgets('購入済みなら目標とグラフが開ける', (tester) async {
    final c = LedgerController(MemoryLedgerRepository(), clock: () => DateTime(2026, 10, 19));
    await c.load();
    await c.finishSetup(rule: const PaydayRule(day: 25), picks: starterEnvelopes.where((e) => e.onByDefault).toList());
    await c.addGoal(name: '旅行', target: 100000);
    await tester.pumpWidget(FuutouApp(
        controller: c, ads: AdService(enabled: false), premium: PremiumStore(enabled: false, unlocked: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('貯金と履歴').last);
    await tester.pumpAndSettle();
    expect(find.text('旅行'), findsOneWidget);
    expect(find.text('あと ¥80,000'), findsOneWidget);
    await tester.tap(find.text('月ごとのグラフ'));
    await tester.pumpAndSettle();
    expect(find.text('使った金額（貯金以外の合計）'), findsOneWidget);
  });
}
