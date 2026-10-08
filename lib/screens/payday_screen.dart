import 'package:flutter/material.dart';

import '../app.dart';
import '../domain/ledger.dart';
import '../domain/yen.dart';
import '../look/coin_badge.dart';
import '../look/envelope_card.dart';
import '../look/kraft_paper.dart';
import '../look/kraft_theme.dart';

/// 給料日の締め。袋ごとに「繰り越す」か「貯金へ」を選ぶ。
class PaydayScreen extends StatefulWidget {
  const PaydayScreen({super.key, this.early = false, this.initialChoices});

  /// 給料日の前に締める（設定の「今日で締める」）
  final bool early;
  final Map<String, Leftover>? initialChoices;

  @override
  State<PaydayScreen> createState() => _PaydayScreenState();
}

class _PaydayScreenState extends State<PaydayScreen> {
  Map<String, Leftover>? _choices;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l = AppScope.of(context).controller.ledger;
    _choices ??= {...l.defaultChoices(), ...?widget.initialChoices};
  }

  void _setAll(Leftover v) {
    final l = AppScope.of(context).controller.ledger;
    setState(() {
      for (final e in l.spendingEnvelopes) {
        final left = l.balanceOf(e);
        if (v == Leftover.save && left <= 0) continue;
        _choices![e.id] = v;
      }
    });
  }

  Future<void> _confirm() async {
    final scope = AppScope.of(context);
    final c = scope.controller;
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    final closed = await c.closePeriod(_choices!, early: widget.early);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _DoneDialog(
        moved: closed.movedToSavings,
        total: c.ledger.totalSaved,
        start: c.ledger.periodStart,
      ),
    );
    nav.pop();
    // ひと区切りのあとにだけ、たまに全画面広告
    await scope.ads.maybeShowInterstitial();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).controller;
    final l = c.ledger;
    final choices = _choices!;
    final moved = l.movedBy(choices);
    final newStart = c.nextPeriodStart(early: widget.early);
    final savingsAfter = l.totalSaved + moved;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.early ? '今日で締める' : '給料日の袋分け'),
        backgroundColor: Kraft.paper,
      ),
      body: KraftPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
          children: [
            Text(
              '${md(l.periodStart)}〜の期間を締めて、${mdW(newStart)}から新しい期間をはじめます。'
              '袋には毎月の予算をもう一度入れます。',
              style: const TextStyle(fontSize: 13.5, color: Kraft.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _setAll(Leftover.carry),
                    child: const Text('ぜんぶ繰り越す'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _setAll(Leftover.save),
                    child: const Text('残りはぜんぶ貯金へ'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final e in l.spendingEnvelopes)
              _LeftoverRow(
                envelope: e,
                left: l.balanceOf(e),
                choice: choices[e.id] ?? Leftover.carry,
                onChanged: (v) => setState(() => choices[e.id] = v),
              ),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CoinBadge(size: 54),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${l.savings.name}へ ${yen(moved, sign: true)}',
                              style: const TextStyle(
                                  fontFamily: Kraft.display, fontSize: 22, color: Kraft.leaf)),
                          const SizedBox(height: 2),
                          Text('締めたあとの貯金 ${yen(savingsAfter)}',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          Text('（このあと毎月の ${yen(l.savings.budget)} も入ります）',
                              style: const TextStyle(fontSize: 12, color: Kraft.inkSoft)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _busy ? null : _confirm,
              child: const Text('袋分けして新しい期間へ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftoverRow extends StatelessWidget {
  const _LeftoverRow({
    required this.envelope,
    required this.left,
    required this.choice,
    required this.onChanged,
  });

  final Envelope envelope;
  final int left;
  final Leftover choice;
  final ValueChanged<Leftover> onChanged;

  @override
  Widget build(BuildContext context) {
    final negative = left < 0;
    final zero = left == 0;
    final segments = negative
        ? const [
            ButtonSegment(value: Leftover.carry, label: Text('マイナスを繰越')),
            ButtonSegment(value: Leftover.clear, label: Text('0にする')),
          ]
        : const [
            ButtonSegment(value: Leftover.carry, label: Text('繰り越す')),
            ButtonSegment(value: Leftover.save, label: Text('貯金へ')),
          ];
    var selected = choice;
    if (!negative && selected == Leftover.clear) selected = Leftover.carry;
    if (negative && selected == Leftover.save) selected = Leftover.carry;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Kraft.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCC8A6)),
      ),
      child: Row(
        children: [
          MiniEnvelope(tint: envelope.tint, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(envelope.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text(
                  negative ? '使いすぎ ${yen(left)}' : 'のこり ${yen(left)}',
                  style: TextStyle(
                    fontFamily: Kraft.display,
                    fontSize: 16,
                    color: negative ? Kraft.stamp : Kraft.ink,
                  ),
                ),
              ],
            ),
          ),
          if (zero)
            const Text('残りなし', style: TextStyle(color: Kraft.inkSoft))
          else
            SegmentedButton<Leftover>(
              segments: segments,
              selected: {selected},
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                backgroundColor: WidgetStateProperty.resolveWith((s) =>
                    s.contains(WidgetState.selected)
                        ? (selected == Leftover.save
                            ? const Color(0xFFDDE7CF)
                            : const Color(0xFFEBDDC2))
                        : const Color(0xFFFBF6EC)),
              ),
              onSelectionChanged: (s) => onChanged(s.first),
            ),
        ],
      ),
    );
  }
}

class _DoneDialog extends StatelessWidget {
  const _DoneDialog({required this.moved, required this.total, required this.start});
  final int moved;
  final int total;
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Kraft.card,
      icon: const CoinBadge(size: 60),
      title: Text(moved > 0 ? '${yen(moved)} を貯金しました' : '新しい期間をはじめました',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: Kraft.display, fontSize: 21)),
      content: Text(
        '貯金の合計は ${yen(total)} です。\n${mdW(start)}から、袋に予算を入れ直しました。',
        textAlign: TextAlign.center,
        style: const TextStyle(height: 1.6),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
