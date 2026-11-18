import 'ledger.dart';

/// グラフの1本分（ひとつの期間）。
class PeriodBar {
  const PeriodBar({
    required this.start,
    required this.end,
    required this.spent,
    required this.budget,
    this.current = false,
  });

  final DateTime start;
  final DateTime end;
  final int spent;

  /// その期間の予算（持ち越し・今期の追加は含めない）
  final int budget;

  /// 今の期間（まだ締めていない）
  final bool current;
}

/// 期間ごとの支出の推移（古い順）。[envelopeName] が null なら貯金以外の合計。
///
/// 締めた期間の記録は袋の名前で残っているので、名前で突き合わせる。
List<PeriodBar> spendingTrend(
  Ledger l, {
  String? envelopeName,
  int maxPeriods = 12,
}) {
  final bars = <PeriodBar>[];
  for (final p in l.history.reversed) {
    var spent = 0;
    var budget = 0;
    for (final r in p.results) {
      if (r.isSavings) continue;
      if (envelopeName != null && r.name != envelopeName) continue;
      spent += r.spent;
      budget += r.budget;
    }
    bars.add(
      PeriodBar(start: p.start, end: p.end, spent: spent, budget: budget),
    );
  }
  var spent = 0;
  var budget = 0;
  for (final e in l.spendingEnvelopes) {
    if (envelopeName != null && e.name != envelopeName) continue;
    spent += l.spentIn(e);
    budget += e.budget;
  }
  bars.add(
    PeriodBar(
      start: l.periodStart,
      end: l.periodEnd,
      spent: spent,
      budget: budget,
      current: true,
    ),
  );
  if (bars.length > maxPeriods) {
    return bars.sublist(bars.length - maxPeriods);
  }
  return bars;
}

/// グラフで選べる袋の名前（今ある袋 → 過去にだけある袋の順）。
List<String> trendEnvelopeNames(Ledger l) {
  final names = <String>[for (final e in l.spendingEnvelopes) e.name];
  for (final p in l.history) {
    for (final r in p.results) {
      if (!r.isSavings && !names.contains(r.name)) names.add(r.name);
    }
  }
  return names;
}
