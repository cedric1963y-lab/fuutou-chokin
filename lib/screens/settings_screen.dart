import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../domain/payday.dart';
import '../domain/yen.dart';
import '../look/kraft_theme.dart';
import 'envelope_editor_screen.dart';
import 'payday_screen.dart';

const siteUrl = 'https://cedric1963y-lab.github.io/fuutou-chokin/';
const privacyUrl = 'https://cedric1963y-lab.github.io/fuutou-chokin/privacy.html';
const termsUrl = 'https://cedric1963y-lab.github.io/fuutou-chokin/terms.html';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Future<void> _pickDay(BuildContext context) async {
    final c = AppScope.of(context).controller;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Kraft.card,
      builder: (ctx) => PaydayDayPicker(current: c.ledger.rule.day),
    );
    if (picked != null) {
      await c.setRule(c.ledger.rule.copyWith(day: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final c = scope.controller;
    return ListenableBuilder(
      listenable: Listenable.merge([c, scope.ads]),
      builder: (context, _) {
        final l = c.ledger;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 0, 10),
                child: Text('設定', style: TextStyle(fontFamily: Kraft.display, fontSize: 26)),
              ),
              _Group(title: '給料日', children: [
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: const Text('給料日'),
                  subtitle: Text('次は ${mdW(l.nextPayday)}'),
                  trailing: Text(l.rule.label,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  onTap: () => _pickDay(context),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.keyboard_double_arrow_left),
                  title: const Text('土日祝なら前の平日にする'),
                  subtitle: const Text('例: 25日が日曜なら23日（金）'),
                  value: l.rule.shiftBeforeRestDay,
                  onChanged: (v) => c.setRule(l.rule.copyWith(shiftBeforeRestDay: v)),
                ),
                ListTile(
                  leading: const Icon(Icons.content_cut),
                  title: const Text('今日で締める'),
                  subtitle: const Text('給料日の前に袋分けをやり直したいとき'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const PaydayScreen(early: true),
                  )),
                ),
              ]),
              _Group(title: '封筒', children: [
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('袋の追加・予算・色・並び順'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const EnvelopeEditorScreen())),
                ),
              ]),
              _Group(title: 'このアプリについて', children: [
                if (scope.ads.privacyOptionsRequired)
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('広告のプライバシー設定'),
                    onTap: scope.ads.showPrivacyOptions,
                  ),
                ListTile(
                  leading: const Icon(Icons.policy_outlined),
                  title: const Text('プライバシーポリシー'),
                  subtitle: const Text('広告（Google AdMob）とデータの扱い'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open(privacyUrl),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('利用規約'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open(termsUrl),
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('サポート・お問い合わせ'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open(siteUrl),
                ),
                ListTile(
                  leading: const Icon(Icons.text_snippet_outlined),
                  title: const Text('ライセンス'),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: '封筒貯金',
                    applicationVersion: '1.0.0',
                  ),
                ),
              ]),
              _Group(title: 'データ', children: [
                const ListTile(
                  leading: Icon(Icons.phone_iphone),
                  title: Text('記録はこのiPhoneの中だけに保存'),
                  subtitle: Text('アカウント・銀行連携なし。アプリを削除すると記録も消えます'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: Kraft.stamp),
                  title: const Text('すべての記録を消す', style: TextStyle(color: Kraft.stamp)),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('すべて消しますか？'),
                        content: const Text('封筒・支出・貯金の記録がすべて消え、最初の設定にもどります。元に戻せません。'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('やめる')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('消す', style: TextStyle(color: Kraft.stamp))),
                        ],
                      ),
                    );
                    if (ok == true) await c.wipeAll();
                  },
                ),
              ]),
              const SizedBox(height: 8),
              const Center(
                child: Text('封筒貯金 1.0.0・広告で無料提供しています',
                    style: TextStyle(fontSize: 12, color: Kraft.inkSoft)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 0, 6),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: Kraft.inkSoft)),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// 1〜30日と「月末」から選ぶ。
class PaydayDayPicker extends StatelessWidget {
  const PaydayDayPicker({super.key, required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('給料日を選ぶ',
                style: TextStyle(fontFamily: Kraft.display, fontSize: 19)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var d = 1; d <= 31; d++)
                  _DayCell(
                    label: d == 31 ? '末' : '$d',
                    selected: d == current || (d == 31 && current >= 31),
                    onTap: () => Navigator.pop(context, d),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('「末」は毎月の最終日。${const PaydayRule(day: 31).label}として計算します。',
                style: const TextStyle(fontSize: 12, color: Kraft.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Kraft.bar : const Color(0xFFFBF6EC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : Kraft.ink,
              )),
        ),
      ),
    );
  }
}
