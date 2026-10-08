import 'payday.dart';
import 'yen.dart';

/// 封筒の色（クラフト紙の色味）。index で保存する。
enum EnvelopeTint { kraft, clay, mustard, sage, slate, rose, ivory, plum }

class Envelope {
  Envelope({
    required this.id,
    required this.name,
    required this.budget,
    this.tint = EnvelopeTint.kraft,
    this.isSavings = false,
    this.carried = 0,
  });

  final String id;
  String name;

  /// 毎期入れる金額（円）。
  int budget;
  EnvelopeTint tint;

  /// 貯金の袋（ひとつだけ）。残りは常に持ち越し、ほかの袋の残りを受け取る。
  final bool isSavings;

  /// 前の期から持ち越した額（マイナスもあり）。
  int carried;

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'budget': budget,
        'tint': tint.index,
        'savings': isSavings,
        'carried': carried,
      };

  static Envelope fromJson(Map<String, dynamic> j) => Envelope(
        id: j['id'] as String,
        name: j['name'] as String,
        budget: (j['budget'] as num).toInt(),
        tint: EnvelopeTint.values[((j['tint'] as num?)?.toInt() ?? 0)
            .clamp(0, EnvelopeTint.values.length - 1)],
        isSavings: j['savings'] as bool? ?? false,
        carried: (j['carried'] as num?)?.toInt() ?? 0,
      );
}

class Spend {
  Spend({
    required this.id,
    required this.envelopeId,
    required this.amount,
    required this.on,
    this.memo = '',
  });

  final String id;
  String envelopeId;
  int amount;
  DateTime on;
  String memo;

  Map<String, Object> toJson() => {
        'id': id,
        'env': envelopeId,
        'amount': amount,
        'on': on.toIso8601String(),
        'memo': memo,
      };

  static Spend fromJson(Map<String, dynamic> j) => Spend(
        id: j['id'] as String,
        envelopeId: j['env'] as String,
        amount: (j['amount'] as num).toInt(),
        on: DateTime.parse(j['on'] as String),
        memo: j['memo'] as String? ?? '',
      );
}

/// 給料日に袋の残りをどうするか。
enum Leftover {
  /// そのまま次の期へ持ち越す（マイナスも引き継ぐ）
  carry,

  /// 貯金の袋へ移す（残りがプラスのときだけ）
  save,

  /// 0 にもどす（マイナスのとき）
  clear,
}

/// 締めた期の、袋ひとつ分の結果。
class EnvelopeResult {
  EnvelopeResult({
    required this.name,
    required this.tint,
    required this.isSavings,
    required this.budget,
    required this.carriedIn,
    required this.spent,
    required this.leftover,
    required this.action,
  });

  final String name;
  final EnvelopeTint tint;
  final bool isSavings;
  final int budget;
  final int carriedIn;
  final int spent;
  final int leftover;
  final Leftover action;

  Map<String, Object> toJson() => {
        'name': name,
        'tint': tint.index,
        'savings': isSavings,
        'budget': budget,
        'in': carriedIn,
        'spent': spent,
        'left': leftover,
        'action': action.index,
      };

  static EnvelopeResult fromJson(Map<String, dynamic> j) => EnvelopeResult(
        name: j['name'] as String,
        tint: EnvelopeTint.values[(j['tint'] as num).toInt()
            .clamp(0, EnvelopeTint.values.length - 1)],
        isSavings: j['savings'] as bool? ?? false,
        budget: (j['budget'] as num).toInt(),
        carriedIn: (j['in'] as num).toInt(),
        spent: (j['spent'] as num).toInt(),
        leftover: (j['left'] as num).toInt(),
        action: Leftover.values[(j['action'] as num).toInt()
            .clamp(0, Leftover.values.length - 1)],
      );
}

class ClosedPeriod {
  ClosedPeriod({
    required this.start,
    required this.end,
    required this.results,
    required this.movedToSavings,
    required this.spends,
  });

  /// 期の初日（給料日）
  final DateTime start;

  /// 期の最終日（次の給料日の前日）
  final DateTime end;
  final List<EnvelopeResult> results;

  /// 残りから貯金へ移した合計
  final int movedToSavings;
  final List<Spend> spends;

  int get totalSpent => results.fold(0, (s, r) => s + r.spent);

  Map<String, Object> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'results': results.map((r) => r.toJson()).toList(),
        'moved': movedToSavings,
        'spends': spends.map((s) => s.toJson()).toList(),
      };

  static ClosedPeriod fromJson(Map<String, dynamic> j) => ClosedPeriod(
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        results: (j['results'] as List)
            .map((e) => EnvelopeResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        movedToSavings: (j['moved'] as num?)?.toInt() ?? 0,
        spends: ((j['spends'] as List?) ?? const [])
            .map((e) => Spend.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 家計の封筒ぜんぶ。純粋なデータと計算だけ（保存や通知は持たない）。
class Ledger {
  Ledger({
    required this.envelopes,
    required this.spends,
    required this.periodStart,
    required this.rule,
    required this.history,
    this.setupDone = true,
  });

  final List<Envelope> envelopes;

  /// 今の期の支出
  final List<Spend> spends;
  DateTime periodStart;
  PaydayRule rule;

  /// 締めた期（新しい順）
  final List<ClosedPeriod> history;
  bool setupDone;

  Envelope get savings => envelopes.firstWhere((e) => e.isSavings);

  Envelope? byId(String id) {
    for (final e in envelopes) {
      if (e.id == id) return e;
    }
    return null;
  }

  int spentIn(Envelope e) => spends
      .where((s) => s.envelopeId == e.id)
      .fold(0, (sum, s) => sum + s.amount);

  /// 今期に袋へ入っている額（持ち越し＋予算）
  int fundedIn(Envelope e) => e.carried + e.budget;

  /// 袋に残っている額
  int balanceOf(Envelope e) => fundedIn(e) - spentIn(e);

  /// 使うための袋（貯金以外）
  Iterable<Envelope> get spendingEnvelopes =>
      envelopes.where((e) => !e.isSavings);

  int get spendableLeft =>
      spendingEnvelopes.fold(0, (s, e) => s + balanceOf(e));

  int get spentThisPeriod => spends.fold(0, (s, x) => s + x.amount);

  /// 貯金の合計（貯金の袋の中身）
  int get totalSaved => balanceOf(savings);

  /// これまでに袋の残りから貯金へ移した合計
  int get movedToSavingsAllTime =>
      history.fold(0, (s, p) => s + p.movedToSavings);

  DateTime get nextPayday => rule.nextAfter(periodStart);

  DateTime get periodEnd =>
      nextPayday.subtract(const Duration(days: 1));

  bool isPaydayDue(DateTime today) =>
      !nextPayday.isAfter(dateOnly(today));

  int daysUntilPayday(DateTime today) =>
      nextPayday.difference(dateOnly(today)).inDays;

  /// 残りの扱いの初期値。プラスは繰り越し、マイナスも繰り越し。
  Map<String, Leftover> defaultChoices() => {
        for (final e in spendingEnvelopes) e.id: Leftover.carry,
      };

  /// 選んだ扱いで、貯金へ移る額の合計。
  int movedBy(Map<String, Leftover> choices) {
    var moved = 0;
    for (final e in spendingEnvelopes) {
      final left = balanceOf(e);
      if (choices[e.id] == Leftover.save && left > 0) moved += left;
    }
    return moved;
  }

  /// 給料日の締め。今の期を履歴へ移し、[newStart] から新しい期を始める。
  ClosedPeriod closePeriod(Map<String, Leftover> choices, DateTime newStart) {
    final start = dateOnly(newStart);
    final results = <EnvelopeResult>[];
    var moved = 0;
    final nextCarried = <String, int>{};
    for (final e in spendingEnvelopes) {
      final left = balanceOf(e);
      var action = choices[e.id] ?? Leftover.carry;
      if (action == Leftover.save && left <= 0) {
        action = left < 0 ? Leftover.carry : Leftover.clear;
      }
      if (action == Leftover.clear && left > 0) action = Leftover.carry;
      switch (action) {
        case Leftover.carry:
          nextCarried[e.id] = left;
        case Leftover.save:
          moved += left;
          nextCarried[e.id] = 0;
        case Leftover.clear:
          nextCarried[e.id] = 0;
      }
      results.add(EnvelopeResult(
        name: e.name,
        tint: e.tint,
        isSavings: false,
        budget: e.budget,
        carriedIn: e.carried,
        spent: spentIn(e),
        leftover: left,
        action: action,
      ));
    }
    final s = savings;
    final savingsLeft = balanceOf(s);
    results.add(EnvelopeResult(
      name: s.name,
      tint: s.tint,
      isSavings: true,
      budget: s.budget,
      carriedIn: s.carried,
      spent: spentIn(s),
      leftover: savingsLeft,
      action: Leftover.carry,
    ));
    nextCarried[s.id] = savingsLeft + moved;

    var end = start.subtract(const Duration(days: 1));
    if (end.isBefore(periodStart)) end = dateOnly(periodStart);
    final closed = ClosedPeriod(
      start: periodStart,
      end: end,
      results: results,
      movedToSavings: moved,
      spends: List.of(spends),
    );
    history.insert(0, closed);
    for (final e in envelopes) {
      e.carried = nextCarried[e.id] ?? 0;
    }
    spends.clear();
    periodStart = start;
    return closed;
  }

  Map<String, Object> toJson() => {
        'v': 1,
        'envelopes': envelopes.map((e) => e.toJson()).toList(),
        'spends': spends.map((s) => s.toJson()).toList(),
        'start': periodStart.toIso8601String(),
        'rule': rule.toJson(),
        'history': history.map((h) => h.toJson()).toList(),
        'setup': setupDone,
      };

  static Ledger fromJson(Map<String, dynamic> j) {
    final ledger = Ledger(
      envelopes: (j['envelopes'] as List)
          .map((e) => Envelope.fromJson(e as Map<String, dynamic>))
          .toList(),
      spends: (j['spends'] as List)
          .map((e) => Spend.fromJson(e as Map<String, dynamic>))
          .toList(),
      periodStart: DateTime.parse(j['start'] as String),
      rule: PaydayRule.fromJson(j['rule'] as Map<String, dynamic>?),
      history: ((j['history'] as List?) ?? const [])
          .map((e) => ClosedPeriod.fromJson(e as Map<String, dynamic>))
          .toList(),
      setupDone: j['setup'] as bool? ?? true,
    );
    ledger.ensureSavings();
    return ledger;
  }

  void ensureSavings() {
    if (!envelopes.any((e) => e.isSavings)) {
      envelopes.add(Envelope(
        id: 'savings',
        name: '貯金',
        budget: 0,
        tint: EnvelopeTint.ivory,
        isSavings: true,
      ));
    }
  }
}

/// はじめの袋の候補。
class StarterEnvelope {
  const StarterEnvelope(this.name, this.budget, this.tint,
      {this.savings = false, this.onByDefault = true});
  final String name;
  final int budget;
  final EnvelopeTint tint;
  final bool savings;
  final bool onByDefault;
}

const starterEnvelopes = <StarterEnvelope>[
  StarterEnvelope('食費', 30000, EnvelopeTint.kraft),
  StarterEnvelope('日用品', 8000, EnvelopeTint.sage),
  StarterEnvelope('外食', 10000, EnvelopeTint.clay),
  StarterEnvelope('娯楽', 10000, EnvelopeTint.mustard),
  StarterEnvelope('交通費', 6000, EnvelopeTint.slate, onByDefault: false),
  StarterEnvelope('医療費', 5000, EnvelopeTint.rose, onByDefault: false),
  StarterEnvelope('衣服・美容', 8000, EnvelopeTint.plum, onByDefault: false),
  StarterEnvelope('予備費', 5000, EnvelopeTint.kraft, onByDefault: false),
  StarterEnvelope('貯金', 20000, EnvelopeTint.ivory, savings: true),
];

/// 袋を追加するときの名前の候補
const envelopeNameIdeas = <String>[
  '交通費', '医療費', '衣服', '美容', '子ども', '交際費', 'ペット', '趣味',
  '予備費', 'プレゼント', '習い事', 'ガソリン',
];
