import 'package:flutter/material.dart';

import '../app.dart';
import '../domain/ledger.dart';
import '../domain/payday.dart';
import '../domain/yen.dart';
import '../look/envelope_card.dart';
import '../look/kraft_paper.dart';
import '../look/kraft_theme.dart';
import 'settings_screen.dart';

/// はじめての起動。給料日と、使う袋を選ぶ。
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  PaydayRule _rule = const PaydayRule();
  final Set<int> _on = {
    for (var i = 0; i < starterEnvelopes.length; i++)
      if (starterEnvelopes[i].onByDefault) i,
  };

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).controller;
    final today = c.today;
    final start = _rule.latestOnOrBefore(today);
    final next = _rule.nextAfter(start);
    return Scaffold(
      body: KraftPaper(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              const Text('封筒貯金へようこそ',
                  style: TextStyle(fontFamily: Kraft.display, fontSize: 27)),
              const SizedBox(height: 8),
              const Text(
                '給料日にお金を「食費」「日用品」などの封筒に分けて、その中だけでやりくりする袋分け貯金を、アプリでかんたんに。'
                '残ったお金は給料日に繰り越すか、貯金の袋へ移せます。',
                style: TextStyle(height: 1.6, color: Kraft.inkSoft),
              ),
              const SizedBox(height: 18),
              const Text('給料日', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 6),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      title: Text(_rule.label,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      subtitle: Text('今の期間 ${md(start)}〜${md(next.subtract(const Duration(days: 1)))}'),
                      trailing: const Text('変更', style: TextStyle(fontWeight: FontWeight.w700)),
                      onTap: () async {
                        final d = await showModalBottomSheet<int>(
                          context: context,
                          backgroundColor: Kraft.card,
                          builder: (_) => PaydayDayPicker(current: _rule.day),
                        );
                        if (d != null) setState(() => _rule = _rule.copyWith(day: d));
                      },
                    ),
                    SwitchListTile(
                      title: const Text('土日祝なら前の平日にする'),
                      value: _rule.shiftBeforeRestDay,
                      onChanged: (v) =>
                          setState(() => _rule = _rule.copyWith(shiftBeforeRestDay: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('使う封筒', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const Text('予算や名前はあとから変えられます。',
                  style: TextStyle(fontSize: 12.5, color: Kraft.inkSoft)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < starterEnvelopes.length; i++)
                    FilterChip(
                      avatar: MiniEnvelope(
                          tint: starterEnvelopes[i].tint,
                          size: 22,
                          savings: starterEnvelopes[i].savings),
                      label: Text(
                          '${starterEnvelopes[i].name} ${yen(starterEnvelopes[i].budget)}'),
                      selected: _on.contains(i),
                      showCheckmark: false,
                      backgroundColor: const Color(0xFFFBF6EC),
                      selectedColor: const Color(0xFFE2C79C),
                      onSelected: starterEnvelopes[i].savings
                          ? null
                          : (v) => setState(() => v ? _on.add(i) : _on.remove(i)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('「貯金」の袋はいつも入っています。',
                  style: TextStyle(fontSize: 12, color: Kraft.inkSoft)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => c.finishSetup(
                  rule: _rule,
                  picks: [
                    for (var i = 0; i < starterEnvelopes.length; i++)
                      if (_on.contains(i) || starterEnvelopes[i].savings) starterEnvelopes[i],
                  ],
                ),
                child: const Text('袋分けをはじめる'),
              ),
              const SizedBox(height: 10),
              const Text(
                '記録はこのiPhoneの中だけに保存します。アカウント登録や銀行連携はありません。アプリは広告つきで無料です。',
                style: TextStyle(fontSize: 12, color: Kraft.inkSoft, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
