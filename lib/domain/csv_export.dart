import 'ledger.dart';

String _d(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _cell(Object v) {
  final s = v.toString();
  if (s.contains(RegExp(r'[",\r\n]'))) return '"${s.replaceAll('"', '""')}"';
  return s;
}

String _rows(List<List<Object>> rows) =>
    // Excel で文字化けしないよう BOM をつけ、改行は CRLF
    '\uFEFF${rows.map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n';

String _action(EnvelopeResult r) {
  if (r.isSavings) return '貯金の袋';
  return switch (r.action) {
    Leftover.save => '貯金へ',
    Leftover.carry => '繰り越し',
    Leftover.clear => '0にもどす',
  };
}

/// 支出と臨時収入の一覧（今の期間＋締めた期間、日付の古い順）。
/// 種類で「支出」と「追加」を分ける。金額はどちらも正の数。
String spendsCsv(Ledger l) {
  final rows = <List<Object>>[
    ['日付', '封筒', '種類', '金額', 'メモ', '期間'],
  ];
  final all = <(DateTime, String, String, int, String, String)>[];
  void addSpend(Spend s, String name, String period) =>
      all.add((s.on, s.id, name, s.amount, s.memo, period));
  void addAddition(Addition a, String name, String period) =>
      all.add((a.on, 'a${a.id}', name, a.amount, a.memo, period));
  // 種類は行を作るときに付けるので、id の頭で区別する
  final kinds = <String, String>{};
  for (final p in l.history) {
    final period = '${_d(p.start)}〜${_d(p.end)}';
    for (final s in p.spends) {
      final name = l.byId(s.envelopeId)?.name ?? '（削除した袋）';
      addSpend(s, name, period);
      kinds[s.id] = '支出';
    }
    for (final a in p.additions) {
      final name = l.byId(a.envelopeId)?.name ?? '（削除した袋）';
      addAddition(a, name, period);
      kinds['a${a.id}'] = '追加';
    }
  }
  final current = '${_d(l.periodStart)}〜（今の期間）';
  for (final s in l.spends) {
    addSpend(s, l.byId(s.envelopeId)?.name ?? '', current);
    kinds[s.id] = '支出';
  }
  for (final a in l.additions) {
    addAddition(a, l.byId(a.envelopeId)?.name ?? '', current);
    kinds['a${a.id}'] = '追加';
  }
  all.sort((a, b) {
    final c = a.$1.compareTo(b.$1);
    return c != 0 ? c : a.$2.compareTo(b.$2);
  });
  for (final (on, id, name, amount, memo, period) in all) {
    rows.add([_d(on), name, kinds[id] ?? '支出', amount, memo, period]);
  }
  return _rows(rows);
}

/// 締めた期間ごと・袋ごとの結果（新しい期間から）。
/// 「今期の追加」は予算とは別の列。
String periodsCsv(Ledger l) {
  final rows = <List<Object>>[
    ['期間のはじめ', '期間のおわり', '封筒', '予算', '前から繰り越し', '今期の追加', '使った', '残り', '残りの扱い'],
  ];
  for (final p in l.history) {
    for (final r in p.results) {
      rows.add([
        _d(p.start),
        _d(p.end),
        r.name,
        r.budget,
        r.carriedIn,
        r.added,
        r.spent,
        r.leftover,
        _action(r),
      ]);
    }
  }
  return _rows(rows);
}
