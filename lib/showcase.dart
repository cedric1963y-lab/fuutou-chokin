import 'domain/ledger.dart';
import 'domain/payday.dart';
import 'persistence/ledger_repository.dart';
import 'state/ledger_controller.dart';

/// ストア用スクリーンショットの撮影モード（debug ビルドのみ。main.dart 参照）。
/// 見本のデータを端末に保存せずメモリだけで使い、広告 SDK には触れない。
class Showcase {
  Showcase._(this.scene, this.controller, this.startTab, this.paydayChoices);

  final String scene;
  final LedgerController controller;
  final int startTab;
  final Map<String, Leftover>? paydayChoices;

  static Showcase build(String scene) {
    switch (scene) {
      case 'payday':
        // 10/25 が日曜なので、給料日は 10/23（金）
        final c = _controller(_current(), DateTime(2026, 10, 23));
        return Showcase._(scene, c, 0, const {
          'food': Leftover.save,
          'daily': Leftover.carry,
          'eatout': Leftover.clear,
          'fun': Leftover.save,
          'kids': Leftover.save,
        });
      case 'history':
        return Showcase._(scene, _controller(_afterPayday(), DateTime(2026, 10, 26)), 1, null);
      case 'spend':
        return Showcase._(scene, _controller(_current(), DateTime(2026, 10, 19)), 0, null);
      default:
        return Showcase._(scene, _controller(_current(), DateTime(2026, 10, 19)), 0, null);
    }
  }

  static LedgerController _controller(Ledger l, DateTime today) {
    final c = LedgerController(MemoryLedgerRepository(l), clock: () => today);
    c.load();
    return c;
  }

  static const _rule = PaydayRule(day: 25, shiftBeforeRestDay: true);

  static List<Envelope> _envelopes({bool fresh = false}) => [
        Envelope(id: 'food', name: '食費', budget: 32000, tint: EnvelopeTint.kraft, carried: fresh ? 0 : 1200),
        Envelope(id: 'daily', name: '日用品', budget: 8000, tint: EnvelopeTint.sage),
        Envelope(id: 'eatout', name: '外食', budget: 10000, tint: EnvelopeTint.clay),
        Envelope(id: 'fun', name: '娯楽', budget: 10000, tint: EnvelopeTint.mustard, carried: fresh ? 2500 : 2500),
        Envelope(id: 'kids', name: '子ども', budget: 6000, tint: EnvelopeTint.slate),
        Envelope(
            id: 'savings',
            name: '貯金',
            budget: 20000,
            tint: EnvelopeTint.ivory,
            isSavings: true,
            carried: fresh ? 122300 : 86400),
      ];

  static int _n = 0;
  static Spend _s(String env, int amount, int m, int d, String memo) =>
      Spend(id: 's${_n++}', envelopeId: env, amount: amount, on: DateTime(2026, m, d), memo: memo);

  static List<Spend> _currentSpends() => [
        _s('food', 6840, 9, 26, 'まとめ買い'),
        _s('food', 2380, 9, 29, 'スーパー'),
        _s('daily', 1980, 9, 30, 'ドラッグストア'),
        _s('food', 3120, 10, 2, 'スーパー'),
        _s('eatout', 3600, 10, 3, 'ランチ（家族）'),
        _s('fun', 1800, 10, 4, '映画'),
        _s('food', 2760, 10, 6, 'スーパー'),
        _s('kids', 1650, 10, 7, '文房具'),
        _s('daily', 2460, 10, 9, 'ティッシュ・洗剤'),
        _s('food', 4290, 10, 10, 'まとめ買い'),
        _s('eatout', 2980, 10, 11, '回転寿司'),
        _s('fun', 3000, 10, 12, '本'),
        _s('food', 1840, 10, 14, 'パン屋'),
        _s('kids', 1150, 10, 15, 'おやつ'),
        _s('daily', 1420, 10, 16, '100円ショップ'),
        _s('food', 2410, 10, 17, 'スーパー'),
        _s('eatout', 4870, 10, 18, '焼肉'),
      ];

  static List<ClosedPeriod> _history() => [
        ClosedPeriod(
          start: DateTime(2026, 8, 25),
          end: DateTime(2026, 9, 24),
          movedToSavings: 15900,
          spends: const [],
          results: [
            _r('食費', EnvelopeTint.kraft, 32000, 0, 30800, Leftover.carry),
            _r('日用品', EnvelopeTint.sage, 8000, 0, 5600, Leftover.save),
            _r('外食', EnvelopeTint.clay, 10000, 0, 6300, Leftover.save),
            _r('娯楽', EnvelopeTint.mustard, 10000, 0, 7500, Leftover.carry),
            _r('子ども', EnvelopeTint.slate, 6000, 0, 2800, Leftover.save),
            EnvelopeResult(
                name: '貯金', tint: EnvelopeTint.ivory, isSavings: true, budget: 20000,
                carriedIn: 50500, spent: 0, leftover: 70500, action: Leftover.carry),
          ],
        ),
        ClosedPeriod(
          start: DateTime(2026, 7, 24),
          end: DateTime(2026, 8, 24),
          movedToSavings: 10500,
          spends: const [],
          results: [
            _r('食費', EnvelopeTint.kraft, 32000, 0, 29300, Leftover.save),
            _r('日用品', EnvelopeTint.sage, 8000, 0, 6200, Leftover.save),
            _r('外食', EnvelopeTint.clay, 10000, 0, 9800, Leftover.carry),
            _r('娯楽', EnvelopeTint.mustard, 10000, 0, 10000, Leftover.carry),
            _r('子ども', EnvelopeTint.slate, 6000, 0, 3000, Leftover.save),
            EnvelopeResult(
                name: '貯金', tint: EnvelopeTint.ivory, isSavings: true, budget: 20000,
                carriedIn: 20000, spent: 0, leftover: 40000, action: Leftover.carry),
          ],
        ),
      ];

  static EnvelopeResult _r(String name, EnvelopeTint t, int budget, int carriedIn, int spent, Leftover a) =>
      EnvelopeResult(
        name: name,
        tint: t,
        isSavings: false,
        budget: budget,
        carriedIn: carriedIn,
        spent: spent,
        leftover: budget + carriedIn - spent,
        action: a,
      );

  static Ledger _current() => Ledger(
        envelopes: _envelopes(),
        spends: _currentSpends(),
        periodStart: DateTime(2026, 9, 25),
        rule: _rule,
        history: _history(),
      );

  /// 10/23 に締めたあと（10/26 時点）。
  static Ledger _afterPayday() {
    final l = _current();
    l.closePeriod(const {
      'food': Leftover.save,
      'daily': Leftover.carry,
      'eatout': Leftover.clear,
      'fun': Leftover.save,
      'kids': Leftover.save,
    }, DateTime(2026, 10, 23));
    l.spends.addAll([
      _s('food', 5980, 10, 24, 'まとめ買い'),
      _s('eatout', 1450, 10, 25, 'カフェ'),
      _s('daily', 880, 10, 26, '電池'),
    ]);
    return l;
  }
}
