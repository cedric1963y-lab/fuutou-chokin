import 'package:flutter/material.dart';

import '../app.dart';
import '../domain/ledger.dart';
import '../domain/yen.dart';
import '../look/envelope_card.dart';
import '../look/kraft_theme.dart';
import 'envelope_editor_screen.dart';
import 'payday_screen.dart';
import 'spend_sheet.dart';

/// 封筒の一覧。タップでそのまま支出を記録する。
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  bool _showcaseOpened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final show = AppScope.of(context).showcase;
    if (show != null && !_showcaseOpened) {
      _showcaseOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (show.scene == 'spend') {
          final c = AppScope.of(context).controller;
          final food = c.ledger.envelopes.first;
          openSpendSheet(context,
              envelopeId: food.id, initialAmount: 1280, initialMemo: 'スーパー（夕飯）');
        } else if (show.scene == 'payday') {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => PaydayScreen(initialChoices: show.paydayChoices),
          ));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final l = c.ledger;
        final envs = l.envelopes;
        return SafeArea(
          bottom: false,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 8, 4),
                      child: Row(
                        children: [
                          const Text('封筒貯金',
                              style: TextStyle(fontFamily: Kraft.display, fontSize: 26)),
                          const Spacer(),
                          IconButton(
                            tooltip: '袋を編集',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const EnvelopeEditorScreen()),
                            ),
                            icon: const Icon(Icons.edit_note, color: Kraft.ink, size: 28),
                          ),
                          const SizedBox(width: 4),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Kraft.bar,
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            onPressed: () => openSpendSheet(context),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('支出を記録'),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _PaydayHeader(ledger: l, today: c.today)),
                  if (c.paydayDue)
                    SliverToBoxAdapter(
                      child: _PaydayDueCard(
                        date: l.nextPayday,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const PaydayScreen()),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    sliver: SliverGrid.builder(
                      itemCount: envs.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.14,
                      ),
                      itemBuilder: (context, i) {
                        final e = envs[i];
                        return EnvelopeCard(
                          name: e.name,
                          tint: e.tint,
                          isSavings: e.isSavings,
                          left: l.balanceOf(e),
                          funded: e.isSavings ? e.budget : l.fundedIn(e),
                          caption: e.isSavings
                              ? '毎月 ${yen(e.budget)} ずつ'
                              : (e.carried != 0
                                  ? '予算+繰越 ${yen(l.fundedIn(e))}'
                                  : '予算 ${yen(e.budget)}'),
                          onTap: () => openSpendSheet(context, envelopeId: e.id),
                          onLongPress: () => showEnvelopeForm(context, envelope: e),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaydayHeader extends StatelessWidget {
  const _PaydayHeader({required this.ledger, required this.today});
  final Ledger ledger;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = ledger.daysUntilPayday(today);
    final left = ledger.spendableLeft;
    final perDay = days > 0 ? (left / days).floor() : left;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Kraft.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCC8A6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('給料日まで ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(days <= 0 ? '今日' : 'あと$days日',
                    style: const TextStyle(fontFamily: Kraft.display, fontSize: 26, height: 1)),
                const Spacer(),
                Text(mdW(ledger.nextPayday),
                    style: const TextStyle(fontSize: 13, color: Kraft.inkSoft)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _Stat(label: '使える残り', value: yen(left), strong: true)),
                Expanded(child: _Stat(label: '1日あたり', value: days > 0 ? yen(perDay) : '—')),
                Expanded(child: _Stat(label: '今期の支出', value: yen(ledger.spentThisPeriod))),
              ],
            ),
            const SizedBox(height: 4),
            Text('今の期間 ${md(ledger.periodStart)}〜${md(ledger.periodEnd)}',
                style: const TextStyle(fontSize: 11.5, color: Kraft.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: Kraft.inkSoft)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: TextStyle(
                fontFamily: Kraft.display,
                fontSize: strong ? 20 : 17,
                color: strong ? Kraft.leaf : Kraft.ink,
              )),
        ),
      ],
    );
  }
}

class _PaydayDueCard extends StatelessWidget {
  const _PaydayDueCard({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Material(
        color: const Color(0xFFF9E3D6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Kraft.stamp, width: 1.4),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Kraft.stamp, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Text('給',
                      style: TextStyle(
                          fontFamily: Kraft.display, fontSize: 22, color: Kraft.stamp)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${mdW(date)}は給料日',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const Text('袋の残りを繰り越すか、貯金へ移して新しい期間をはじめましょう',
                          style: TextStyle(fontSize: 12.5, color: Kraft.inkSoft)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Kraft.stamp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
