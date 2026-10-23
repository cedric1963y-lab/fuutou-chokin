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

/// 支出の一覧（今の期間＋締めた期間、日付の古い順）。
String spendsCsv(Ledger l) {
  final rows = <List<Object>>[
    ['日付', '封筒', '金額', 'メモ', '期間'],
  ];
  final all = <(Spend, String, String)>[];
  for (final p in l.history) {
    for (final s in p.spends) {
      all.add((s, l.byId(s.envelopeId)?.name ?? '（削除した袋）', '${_d(p.start)}〜${_d(p.end)}'));
    }
  }
  for (final s in l.spends) {
    all.add((s, l.byId(s.envelopeId)?.name ?? '', '${_d(l.periodStart)}〜（今の期間）'));
  }
  all.sort((a, b) {
    final c = a.$1.on.compareTo(b.$1.on);
    return c != 0 ? c : a.$1.id.compareTo(b.$1.id);
  });
  for (final (s, name, period) in all) {
    rows.add([_d(s.on), name, s.amount, s.memo, period]);
  }
  return _rows(rows);
}

/// 締めた期間ごと・袋ごとの結果（新しい期間から）。
String periodsCsv(Ledger l) {
  final rows = <List<Object>>[
    ['期間のはじめ', '期間のおわり', '封筒', '予算', '前から繰り越し', '使った', '残り', '残りの扱い'],
  ];
  for (final p in l.history) {
    for (final r in p.results) {
      rows.add([
        _d(p.start),
        _d(p.end),
        r.name,
        r.budget,
        r.carriedIn,
        r.spent,
        r.leftover,
        _action(r),
      ]);
    }
  }
  return _rows(rows);
}
