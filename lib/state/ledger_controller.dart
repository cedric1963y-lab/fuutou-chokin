import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/ledger.dart';
import '../domain/payday.dart';
import '../domain/yen.dart';
import '../persistence/ledger_repository.dart';

/// 画面から使う家計の状態。変更のたびに端末へ保存する。
class LedgerController extends ChangeNotifier {
  LedgerController(this._repo, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final LedgerRepository _repo;
  final DateTime Function() _clock;
  Ledger? _ledger;
  bool _loaded = false;

  bool get loaded => _loaded;
  bool get needsSetup => _ledger == null || !_ledger!.setupDone;
  Ledger get ledger => _ledger!;
  DateTime get today => dateOnly(_clock());

  final _rand = Random();
  String _newId() =>
      '${_clock().microsecondsSinceEpoch.toRadixString(36)}${_rand.nextInt(1 << 20).toRadixString(36)}';

  Future<void> load() async {
    _ledger = await _repo.read();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _commit() async {
    notifyListeners();
    final l = _ledger;
    if (l != null) await _repo.write(l);
  }

  /// はじめての設定。今日以前で最も近い給料日から期を始める。
  Future<void> finishSetup({
    required PaydayRule rule,
    required List<StarterEnvelope> picks,
  }) async {
    final envelopes = <Envelope>[];
    var i = 0;
    for (final p in picks) {
      envelopes.add(Envelope(
        id: p.savings ? 'savings' : 'e${i++}${_newId()}',
        name: p.name,
        budget: p.budget,
        tint: p.tint,
        isSavings: p.savings,
      ));
    }
    final ledger = Ledger(
      envelopes: envelopes,
      spends: [],
      periodStart: rule.latestOnOrBefore(today),
      rule: rule,
      history: [],
    );
    ledger.ensureSavings();
    _ledger = ledger;
    await _commit();
  }

  // ---- 支出 ----

  Future<Spend> addSpend({
    required String envelopeId,
    required int amount,
    DateTime? on,
    String memo = '',
  }) async {
    final s = Spend(
      id: _newId(),
      envelopeId: envelopeId,
      amount: amount,
      on: dateOnly(on ?? today),
      memo: memo.trim(),
    );
    ledger.spends.add(s);
    await _commit();
    return s;
  }

  Future<void> updateSpend(Spend s,
      {String? envelopeId, int? amount, DateTime? on, String? memo}) async {
    if (envelopeId != null) s.envelopeId = envelopeId;
    if (amount != null) s.amount = amount;
    if (on != null) s.on = dateOnly(on);
    if (memo != null) s.memo = memo.trim();
    await _commit();
  }

  Future<void> removeSpend(Spend s) async {
    ledger.spends.removeWhere((x) => x.id == s.id);
    await _commit();
  }

  Future<void> restoreSpend(Spend s) async {
    if (ledger.spends.any((x) => x.id == s.id)) return;
    ledger.spends.add(s);
    await _commit();
  }

  /// 新しい順
  List<Spend> spendsNewestFirst({String? envelopeId}) {
    final list = ledger.spends
        .where((s) => envelopeId == null || s.envelopeId == envelopeId)
        .toList();
    list.sort((a, b) {
      final c = b.on.compareTo(a.on);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
    return list;
  }

  // ---- 袋 ----

  Future<Envelope> addEnvelope(
      {required String name, required int budget, required EnvelopeTint tint}) async {
    final e = Envelope(id: _newId(), name: name.trim(), budget: budget, tint: tint);
    final savingsIndex = ledger.envelopes.indexWhere((x) => x.isSavings);
    if (savingsIndex >= 0) {
      ledger.envelopes.insert(savingsIndex, e);
    } else {
      ledger.envelopes.add(e);
    }
    await _commit();
    return e;
  }

  Future<void> updateEnvelope(Envelope e,
      {String? name, int? budget, EnvelopeTint? tint}) async {
    if (name != null && name.trim().isNotEmpty) e.name = name.trim();
    if (budget != null) e.budget = budget;
    if (tint != null) e.tint = tint;
    await _commit();
  }

  Future<void> removeEnvelope(Envelope e) async {
    if (e.isSavings) return;
    ledger.envelopes.removeWhere((x) => x.id == e.id);
    ledger.spends.removeWhere((s) => s.envelopeId == e.id);
    await _commit();
  }

  Future<void> reorderEnvelopes(int oldIndex, int newIndex) async {
    // newIndex は取り除いたあとの位置（onReorderItem）
    final list = ledger.envelopes;
    final e = list.removeAt(oldIndex);
    list.insert(newIndex, e);
    await _commit();
  }

  // ---- 給料日 ----

  Future<void> setRule(PaydayRule rule) async {
    ledger.rule = rule;
    // 期の初日を新しい決まりで今日以前の給料日に合わせ直す（記録は残す）
    final aligned = rule.latestOnOrBefore(today);
    if (!aligned.isBefore(ledger.periodStart) || ledger.spends.isEmpty) {
      ledger.periodStart = aligned;
    }
    await _commit();
  }

  bool get paydayDue => ledger.isPaydayDue(today);

  /// 締めたあとの新しい期の初日。何か月も開いていなくても今日以前の給料日。
  DateTime nextPeriodStart({bool early = false}) {
    if (early || !paydayDue) return today;
    return ledger.rule.latestOnOrBefore(today);
  }

  Future<ClosedPeriod> closePeriod(Map<String, Leftover> choices,
      {bool early = false}) async {
    final closed = ledger.closePeriod(choices, nextPeriodStart(early: early));
    await _commit();
    return closed;
  }

  Future<void> wipeAll() async {
    await _repo.wipe();
    _ledger = null;
    notifyListeners();
  }
}
