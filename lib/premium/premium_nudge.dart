import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app.dart';
import '../look/kraft_theme.dart';
import 'premium_screen.dart';

/// 封筒の一覧の上に出す、やわらかいプレミアムの案内（買い切り）。
///
/// 出す条件（すべて満たすとき）：
///  - まだプレミアムを買っていない
///  - 支出を5件以上記録していて、起動3回目以降（使い慣れてから）
///  - 閉じた回数が3回未満、かつ前に閉じてから14日以上たっている
/// 閉じる（×）か、案内画面を開いた時点で「閉じた」とみなす。
/// 全画面の表示や広告ではなく、一覧の上にある1枚のカードだけ。
class PremiumNudge extends StatefulWidget {
  const PremiumNudge({super.key});

  static const minSpends = 5;
  static const minLaunches = 3;
  static const maxDismiss = 3;
  static const quiet = Duration(days: 14);

  static const kDismissedAt = 'fuutou.nudge.dismissedAt';
  static const kDismissCount = 'fuutou.nudge.dismissCount';
  // RatingAsk と同じ保存キー（使い込み具合の目安）
  static const kSpendCount = 'fuutou.rating.spendCount';
  static const kLaunches = 'fuutou.rating.launches';

  /// 出してよいかの判定（テスト用に切り出し）。
  static bool shouldShow({
    required DateTime now,
    required int spends,
    required int launches,
    required int dismissCount,
    required int? dismissedAtMs,
  }) {
    if (spends < minSpends) return false;
    if (launches < minLaunches) return false;
    if (dismissCount >= maxDismiss) return false;
    if (dismissedAtMs != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(dismissedAtMs)) < quiet) {
      return false;
    }
    return true;
  }

  @override
  State<PremiumNudge> createState() => _PremiumNudgeState();
}

class _PremiumNudgeState extends State<PremiumNudge> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final ok = PremiumNudge.shouldShow(
        now: DateTime.now(),
        spends: p.getInt(PremiumNudge.kSpendCount) ?? 0,
        launches: p.getInt(PremiumNudge.kLaunches) ?? 0,
        dismissCount: p.getInt(PremiumNudge.kDismissCount) ?? 0,
        dismissedAtMs: p.getInt(PremiumNudge.kDismissedAt),
      );
      if (mounted && ok) setState(() => _show = true);
    } catch (_) {}
  }

  Future<void> _markDismissed() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(PremiumNudge.kDismissCount, (p.getInt(PremiumNudge.kDismissCount) ?? 0) + 1);
      await p.setInt(PremiumNudge.kDismissedAt, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.premium,
      builder: (context, _) {
        if (!_show || scope.premium.unlocked || scope.showcase != null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                _markDismissed();
                setState(() => _show = false);
                openPremium(context);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, color: Kraft.coinDeep),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('広告なしで、もっと便利に',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('貯金の目標・月ごとのグラフ・CSV書き出し（買い切り）',
                              style: TextStyle(fontSize: 12.5, color: Kraft.inkSoft)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '閉じる',
                      icon: const Icon(Icons.close, size: 20, color: Kraft.inkSoft),
                      onPressed: () {
                        _markDismissed();
                        setState(() => _show = false);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
