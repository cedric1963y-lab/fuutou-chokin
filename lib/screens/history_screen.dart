import 'package:flutter/material.dart';

import '../app.dart';
import '../domain/ledger.dart';
import '../domain/yen.dart';
import '../look/coin_badge.dart';
import '../look/envelope_card.dart';
import '../look/kraft_theme.dart';
import 'spend_sheet.dart';

/// 貯金の合計と、期間ごとの履歴。
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final l = c.ledger;
        final spends = c.spendsNewestFirst();
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 0, 10),
                child: Text('貯金と履歴',
                    style: TextStyle(fontFamily: Kraft.display, fontSize: 26)),
              ),
              _SavedTotal(ledger: l),
              const SizedBox(height: 18),
              _SectionTitle(
                '今の期間 ${md(l.periodStart)}〜${md(l.periodEnd)}',
                trailing: '支出 ${yen(l.spentThisPeriod)}',
              ),
              if (spends.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('まだ記録がありません。封筒をタップすると記録できます。',
                      style: TextStyle(color: Kraft.inkSoft)),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < spends.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 56),
                        _SpendTile(spend: spends[i], ledger: l),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              if (l.history.isNotEmpty) const _SectionTitle('締めた期間'),
              for (var i = 0; i < l.history.length; i++)
                _ClosedCard(period: l.history[i], expanded: i == 0),
            ],
          ),
        );
      },
    );
  }
}

class _SavedTotal extends StatelessWidget {
  const _SavedTotal({required this.ledger});
  final Ledger ledger;

  @override
  Widget build(BuildContext context) {
    final moves = ledger.history.where((p) => p.movedToSavings > 0).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Kraft.tint(EnvelopeTint.ivory),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC9B08A), width: 1.2),
      ),
      child: Row(
        children: [
          const CoinBadge(size: 70),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${ledger.savings.name}の合計',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Kraft.inkSoft)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(yen(ledger.totalSaved),
                      style: const TextStyle(fontFamily: Kraft.display, fontSize: 36, height: 1.15)),
                ),
                const SizedBox(height: 2),
                Text(
                  moves > 0
                      ? '袋の残りから ${yen(ledger.movedToSavingsAllTime, sign: true)}（$moves回）'
                      : '給料日に袋の残りを貯金へ移すと、ここに増えていきます',
                  style: const TextStyle(fontSize: 12.5, color: Kraft.leaf, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});
  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          if (trailing != null)
            Text(trailing!, style: const TextStyle(fontSize: 13, color: Kraft.inkSoft)),
        ],
      ),
    );
  }
}

class _SpendTile extends StatelessWidget {
  const _SpendTile({required this.spend, required this.ledger});
  final Spend spend;
  final Ledger ledger;

  @override
  Widget build(BuildContext context) {
    final env = ledger.byId(spend.envelopeId);
    return ListTile(
      dense: true,
      leading: MiniEnvelope(
          tint: env?.tint ?? EnvelopeTint.kraft, size: 30, savings: env?.isSavings ?? false),
      title: Text(spend.memo.isEmpty ? (env?.name ?? '') : spend.memo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
      subtitle: Text('${mdW(spend.on)}・${env?.name ?? ''}',
          style: const TextStyle(fontSize: 12, color: Kraft.inkSoft)),
      trailing: Text(yen(spend.amount),
          style: const TextStyle(fontFamily: Kraft.display, fontSize: 17)),
      onTap: () => openSpendSheet(context, editing: spend),
    );
  }
}

class _ClosedCard extends StatelessWidget {
  const _ClosedCard({required this.period, this.expanded = false});
  final ClosedPeriod period;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          title: Text('${md(period.start)}〜${md(period.end)}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
            '支出 ${yen(period.totalSpent)}・貯金へ ${yen(period.movedToSavings, sign: true)}',
            style: const TextStyle(fontSize: 12.5, color: Kraft.inkSoft),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: [
            for (final r in period.results)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    MiniEnvelope(tint: r.tint, size: 24, savings: r.isSavings),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text('使った ${yen(r.spent)}',
                        style: const TextStyle(fontSize: 12.5, color: Kraft.inkSoft)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 92,
                      child: Text(
                        r.isSavings
                            ? yen(r.leftover)
                            : '${yen(r.leftover)} ${_tag(r.action, r.leftover)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: r.leftover < 0
                              ? Kraft.stamp
                              : (r.action == Leftover.save ? Kraft.leaf : Kraft.ink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _tag(Leftover a, int left) => switch (a) {
        Leftover.save => '貯金',
        Leftover.carry => left == 0 ? '' : '繰越',
        Leftover.clear => '0に',
      };
}
