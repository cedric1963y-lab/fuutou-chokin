import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../domain/ledger.dart';
import '../look/coin_badge.dart';
import '../look/envelope_card.dart';
import '../look/kraft_paper.dart';
import '../look/kraft_theme.dart';
import 'premium_store.dart';

const _termsUrl = 'https://cedric1963y-lab.github.io/fuutou-chokin/terms.html';
const _privacyUrl = 'https://cedric1963y-lab.github.io/fuutou-chokin/privacy.html';

/// プレミアムの案内（買い切り）。どの画面からでも開ける。
Future<void> openPremium(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PremiumScreen()),
    );

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  Future<void> _buy(BuildContext context) async {
    final store = AppScope.of(context).premium;
    final messenger = ScaffoldMessenger.of(context);
    final r = await store.buy();
    final text = premiumResultText(r);
    if (text != null) messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).premium;
    return Scaffold(
      appBar: AppBar(title: const Text('プレミアム'), backgroundColor: Kraft.paper),
      body: KraftPaper(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                const _Hero(),
                const SizedBox(height: 16),
                const _Feature(
                  icon: Icons.flag_outlined,
                  title: '貯金の目標',
                  body: '「旅行 10万円」のように目標を決めると、貯金の合計から「あと◯円」と進み具合を見せます。',
                ),
                const _Feature(
                  icon: Icons.bar_chart_rounded,
                  title: '月ごとのグラフ',
                  body: '袋ごとに、期間ごとの支出と予算の推移を棒グラフで見くらべられます。',
                ),
                const _Feature(
                  icon: Icons.ios_share,
                  title: 'CSV書き出し',
                  body: '支出の記録と、締めた期間の結果をCSVにして、Excelや家計簿ソフトへ移せます。',
                ),
                const _Feature(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: '広告なし',
                  body: '画面下のバナーも、ときどき出る全画面の広告も表示しません。',
                ),
                const SizedBox(height: 6),
                const Text(
                  '封筒の数や、今ある機能はこれまでどおり無料で使えます。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Kraft.inkSoft, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (store.unlocked)
                  const _OwnedBadge()
                else ...[
                  FilledButton(
                    onPressed: store.busy ? null : () => _buy(context),
                    child: store.busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text('${store.price}で購入する（買い切り）'),
                  ),
                  if (store.pending)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('購入の承認待ちです。承認されると自動で使えるようになります。',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: Kraft.inkSoft)),
                    ),
                  const SizedBox(height: 4),
                  RestoreButton(store: store),
                ],
                const SizedBox(height: 10),
                const Text(
                  '一度の購入で、同じ Apple ID のiPhoneでずっと使えます。定期的な請求はありません。お支払いは Apple ID に請求されます。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Kraft.inkSoft, height: 1.5),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse(_termsUrl), mode: LaunchMode.externalApplication),
                      child: const Text('利用規約', style: TextStyle(fontSize: 12)),
                    ),
                    const Text('・', style: TextStyle(color: Kraft.inkSoft)),
                    TextButton(
                      onPressed: () => launchUrl(Uri.parse(_privacyUrl), mode: LaunchMode.externalApplication),
                      child: const Text('プライバシーポリシー', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 「購入を復元」ボタン（設定画面と案内画面で使う）。
class RestoreButton extends StatelessWidget {
  const RestoreButton({super.key, required this.store});
  final PremiumStore store;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: store.busy
          ? null
          : () async {
              final messenger = ScaffoldMessenger.of(context);
              final r = await store.restore();
              final text = premiumResultText(r, restoring: true);
              if (text != null) messenger.showSnackBar(SnackBar(content: Text(text)));
            },
      child: const Text('購入を復元', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Kraft.tint(EnvelopeTint.ivory),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Kraft.line, width: 1.2),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MiniEnvelope(tint: EnvelopeTint.sage, size: 46),
              SizedBox(width: 8),
              CoinBadge(size: 62),
              SizedBox(width: 8),
              MiniEnvelope(tint: EnvelopeTint.clay, size: 46),
            ],
          ),
          SizedBox(height: 12),
          Text('封筒貯金 プレミアム',
              style: TextStyle(fontFamily: Kraft.display, fontSize: 24)),
          SizedBox(height: 4),
          Text('貯めるのが、もっと楽しくなる4つの道具',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Kraft.inkSoft)),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE2C79C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Kraft.bar),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontSize: 13, color: Kraft.inkSoft, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnedBadge extends StatelessWidget {
  const _OwnedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6EBDA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Kraft.leaf.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, color: Kraft.leaf),
          SizedBox(width: 8),
          Text('プレミアムをご利用中です',
              style: TextStyle(fontWeight: FontWeight.w800, color: Kraft.leaf, fontSize: 15.5)),
        ],
      ),
    );
  }
}

/// まだ買っていない人に見せる、やわらかい案内カード。タップで案内画面へ。
class LockedTeaser extends StatelessWidget {
  const LockedTeaser({super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openPremium(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Icon(icon, color: Kraft.inkSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(body, style: const TextStyle(fontSize: 12.5, color: Kraft.inkSoft)),
                  ],
                ),
              ),
              const PremiumTag(),
              const Icon(Icons.chevron_right, color: Kraft.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

/// 小さな「プレミアム」の札。
class PremiumTag extends StatelessWidget {
  const PremiumTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1DDA8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Kraft.coinDeep.withValues(alpha: 0.6)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 12, color: Kraft.coinDeep),
          SizedBox(width: 3),
          Text('プレミアム',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Kraft.coinDeep)),
        ],
      ),
    );
  }
}
