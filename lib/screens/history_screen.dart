import 'package:flutter/material.dart';

import '../app.dart';
import '../domain/ledger.dart';
import '../domain/yen.dart';
import '../look/coin_badge.dart';
import '../look/envelope_card.dart';
import '../look/kraft_theme.dart';
import '../premium/csv_share.dart';
import '../premium/premium_screen.dart';
import 'goals_screen.dart';
import 'spend_sheet.dart';
import 'trend_screen.dart';

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
        final additions = c.additionsNewestFirst();
        final lines =
            <_HistoryLine>[
              for (final s in spends) _HistoryLine.spend(s),
              for (final a in additions) _HistoryLine.addition(a),
            ]..sort((a, b) {
              final c = b.on.compareTo(a.on);
              return c != 0 ? c : b.id.compareTo(a.id);
            });
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 0, 10),
                child: Text(
                  '貯金と履歴',
                  style: TextStyle(fontFamily: Kraft.display, fontSize: 26),
                ),
              ),
              _SavedTotal(ledger: l),
              const SizedBox(height: 12),
              const _PremiumTools(),
              const SizedBox(height: 18),
              _SectionTitle(
                '今の期間 ${md(l.periodStart)}〜${md(l.periodEnd)}',
                trailing: '支出 ${yen(l.spentThisPeriod)}',
              ),
              if (lines.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'まだ記録がありません。封筒をタップすると記録できます。',
                    style: TextStyle(color: Kraft.inkSoft),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < lines.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 56),
                        if (lines[i].spend != null)
                          _SpendTile(spend: lines[i].spend!, ledger: l)
                        else
                          _AdditionTile(
                            addition: lines[i].addition!,
                            ledger: l,
                          ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              if (l.history.isNotEmpty) const _SectionTitle('締めた期間'),
              for (var i = 0; i < l.history.length; i++)
                _ClosedCard(period: l.history[i], ledger: l, expanded: i == 0),
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
                Text(
                  '${ledger.savings.name}の合計',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Kraft.inkSoft,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    yen(ledger.totalSaved),
                    style: const TextStyle(
                      fontFamily: Kraft.display,
                      fontSize: 36,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  moves > 0
                      ? '袋の残りから ${yen(ledger.movedToSavingsAllTime, sign: true)}（$moves回）'
                      : '給料日に袋の残りを貯金へ移すと、ここに増えていきます',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Kraft.leaf,
                    fontWeight: FontWeight.w700,
                  ),
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
  const _SectionTitle(this.text, {this.trailing, this.action});
  final String text;
  final String? trailing;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(fontSize: 13, color: Kraft.inkSoft),
            ),
          ?action,
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
        tint: env?.tint ?? EnvelopeTint.kraft,
        size: 30,
        savings: env?.isSavings ?? false,
      ),
      title: Text(
        spend.memo.isEmpty ? (env?.name ?? '') : spend.memo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
      subtitle: Text(
        '${mdW(spend.on)}・${env?.name ?? ''}',
        style: const TextStyle(fontSize: 12, color: Kraft.inkSoft),
      ),
      trailing: Text(
        yen(spend.amount),
        style: const TextStyle(fontFamily: Kraft.display, fontSize: 17),
      ),
      onTap: () => openSpendSheet(context, editing: spend),
    );
  }
}

class _HistoryLine {
  _HistoryLine.spend(this.spend) : addition = null;
  _HistoryLine.addition(this.addition) : spend = null;
  final Spend? spend;
  final Addition? addition;
  DateTime get on => spend?.on ?? addition!.on;
  String get id => spend?.id ?? addition!.id;
}

class _AdditionTile extends StatelessWidget {
  const _AdditionTile({required this.addition, required this.ledger});
  final Addition addition;
  final Ledger ledger;

  @override
  Widget build(BuildContext context) {
    final env = ledger.byId(addition.envelopeId);
    return ListTile(
      dense: true,
      leading: MiniEnvelope(
        tint: env?.tint ?? EnvelopeTint.kraft,
        size: 30,
        savings: env?.isSavings ?? false,
      ),
      title: Text(
        addition.memo.isEmpty ? '臨時収入' : addition.memo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
      subtitle: Text(
        '${mdW(addition.on)}・${env?.name ?? ''}・追加',
        style: const TextStyle(fontSize: 12, color: Kraft.inkSoft),
      ),
      trailing: Text(
        yen(addition.amount, sign: true),
        style: const TextStyle(
          fontFamily: Kraft.display,
          fontSize: 17,
          color: Kraft.leaf,
        ),
      ),
      onTap: () => openSpendSheet(context, editingAddition: addition),
    );
  }
}

class _ClosedCard extends StatelessWidget {
  const _ClosedCard({
    required this.period,
    required this.ledger,
    this.expanded = false,
  });
  final ClosedPeriod period;
  final Ledger ledger;
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
          title: Text(
            '${md(period.start)}〜${md(period.end)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
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
                    Expanded(
                      child: Text(
                        r.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      r.added != 0
                          ? '追加 ${yen(r.added, sign: true)}・使った ${yen(r.spent)}'
                          : '使った ${yen(r.spent)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: r.added != 0 ? Kraft.leaf : Kraft.inkSoft,
                      ),
                    ),
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
                              : (r.action == Leftover.save
                                    ? Kraft.leaf
                                    : Kraft.ink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (period.additions.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '臨時収入',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Kraft.leaf,
                    ),
                  ),
                ),
              ),
              for (final a in period.additions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${mdW(a.on)}　${ledger.byId(a.envelopeId)?.name ?? ''}　${a.memo.isEmpty ? '追加' : a.memo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Kraft.inkSoft,
                          ),
                        ),
                      ),
                      Text(
                        yen(a.amount, sign: true),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Kraft.leaf,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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

/// 貯金の目標・グラフ・CSV（プレミアム）。買う前はやわらかい案内だけを出す。
class _PremiumTools extends StatelessWidget {
  const _PremiumTools();

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final c = scope.controller;
    return ListenableBuilder(
      listenable: scope.premium,
      builder: (context, _) {
        final unlocked = scope.premium.unlocked;
        final goals = unlocked ? c.goalProgress : const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (unlocked) ...[
              _SectionTitle(
                '貯金の目標',
                action: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GoalsScreen(),
                    ),
                  ),
                  child: Text(goals.isEmpty ? '追加' : '編集'),
                ),
              ),
              if (goals.isEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text(
                      '目標を決める',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text('例: 旅行 10万円 → 「あと◯円」がわかります'),
                    trailing: const Icon(Icons.add),
                    onTap: () => showGoalForm(context),
                  ),
                )
              else
                for (final p in goals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GoalTile(
                      progress: p,
                      onTap: () => showGoalForm(context, goal: p.goal),
                    ),
                  ),
            ] else
              const LockedTeaser(
                icon: Icons.flag_outlined,
                title: '貯金の目標',
                body: '「旅行 10万円まで あと◯円」を表示できます',
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ToolButton(
                    icon: Icons.bar_chart_rounded,
                    label: '月ごとのグラフ',
                    locked: !unlocked,
                    onTap: () => unlocked
                        ? Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TrendScreen(),
                            ),
                          )
                        : openPremium(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Builder(
                    builder: (btnContext) => _ToolButton(
                      icon: Icons.ios_share,
                      label: 'CSV書き出し',
                      locked: !unlocked,
                      onTap: () => unlocked
                          ? shareCsv(btnContext, c.ledger)
                          : openPremium(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.locked,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: locked ? Kraft.inkSoft : Kraft.ink),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: locked ? Kraft.inkSoft : Kraft.ink,
                  ),
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 4),
                const Icon(Icons.lock_outline, size: 15, color: Kraft.coinDeep),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
