import 'package:flutter_test/flutter_test.dart';
import 'package:fuutou_chokin/app.dart';
import 'package:fuutou_chokin/monetization/ad_service.dart';
import 'package:fuutou_chokin/persistence/ledger_repository.dart';
import 'package:fuutou_chokin/state/ledger_controller.dart';

void main() {
  testWidgets('はじめての設定から封筒の一覧まで', (tester) async {
    final c = LedgerController(MemoryLedgerRepository(), clock: () => DateTime(2026, 10, 19));
    await c.load();
    await tester.pumpWidget(FuutouApp(controller: c, ads: AdService(enabled: false)));
    await tester.pumpAndSettle();
    expect(find.text('封筒貯金へようこそ'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('袋分けをはじめる'), 200);
    await tester.tap(find.text('袋分けをはじめる'));
    await tester.pumpAndSettle();
    expect(find.text('支出を記録'), findsOneWidget);
    expect(find.text('食費'), findsWidgets);
    expect(c.ledger.periodStart, DateTime(2026, 9, 25));
  });
}
