import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App Store の評価（Apple 標準の requestReview）をお願いするタイミングの管理。
///
/// お願いするのは、うまくいった直後のどちらかだけ。
///  A. 2回目以降の「給料日の締め」が終わったとき（その回は全画面広告を出さない）
///  B. 支出を合計10件以上、3日以上に分けて記録したあと、1件記録し終えたとき
/// 共通の条件：
///  - 起動3回目以降、かつ初めて使った日とは別の日
///  - 起動から60秒以上たっている
///  - 全画面広告から2分以上あいている
///  - 1つのバージョンにつき1回まで（年3回までの制限は iOS 側でかかる）
/// 独自の前置きや「★5を」などの文言は出さない。
class RatingAsk {
  const RatingAsk({this.enabled = true});

  /// テスト・撮影モードでは false（何も保存せず、何も出さない）
  final bool enabled;

  static const version = '1.1.2';
  static const minLaunches = 3;
  static const minSpends = 10;
  static const minSpendDays = 3;
  static const minClosings = 2;
  static const warmUp = Duration(seconds: 60);
  static const adQuiet = Duration(minutes: 2);

  static const _kLaunches = 'fuutou.rating.launches';
  static const _kFirstDay = 'fuutou.rating.firstDay';
  static const _kSpendCount = 'fuutou.rating.spendCount';
  static const _kSpendDays = 'fuutou.rating.spendDays';
  static const _kAskedFor = 'fuutou.rating.askedVersion';
  static const _kLastInterstitial = 'fuutou.ads.lastInterstitial';

  static DateTime? _openedAt;

  bool get _platformOk =>
      enabled &&
      !kIsWeb &&
      Platform.isIOS &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 起動のたびに1回。
  Future<void> noteLaunch() async {
    if (!_platformOk) return;
    _openedAt = DateTime.now();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kLaunches, (p.getInt(_kLaunches) ?? 0) + 1);
      if (p.getString(_kFirstDay) == null) {
        await p.setString(_kFirstDay, _day(DateTime.now()));
      }
    } catch (_) {}
  }

  /// 支出を新しく記録し終えた（入力シートが閉じた）あと。
  Future<void> afterSpendSaved(DateTime spentOn) async {
    if (!_platformOk) return;
    try {
      final p = await SharedPreferences.getInstance();
      final count = (p.getInt(_kSpendCount) ?? 0) + 1;
      await p.setInt(_kSpendCount, count);
      final days = {...?p.getStringList(_kSpendDays)};
      if (days.length < minSpendDays) {
        days.add(_day(spentOn));
        await p.setStringList(_kSpendDays, days.toList());
      }
      if (count < minSpends || days.length < minSpendDays) return;
      if (!await _commonOk(p)) return;
      await _ask(p, delay: const Duration(milliseconds: 1200));
    } catch (_) {}
  }

  /// 給料日の締めが終わった直後。お願いしたら true（その回は全画面広告を出さない）。
  Future<bool> afterPaydayClosed(int closingsSoFar) async {
    if (!_platformOk || closingsSoFar < minClosings) return false;
    try {
      final p = await SharedPreferences.getInstance();
      if (!await _commonOk(p)) return false;
      return await _ask(p, delay: const Duration(milliseconds: 700));
    } catch (_) {
      return false;
    }
  }

  Future<bool> _commonOk(SharedPreferences p) async {
    return shouldAsk(
      now: DateTime.now(),
      openedAt: _openedAt,
      launches: p.getInt(_kLaunches) ?? 0,
      firstDay: p.getString(_kFirstDay),
      askedFor: p.getString(_kAskedFor),
      lastInterstitialMs: p.getInt(_kLastInterstitial),
    );
  }

  /// 共通の条件の判定（テスト用に切り出し）。
  static bool shouldAsk({
    required DateTime now,
    required DateTime? openedAt,
    required int launches,
    required String? firstDay,
    required String? askedFor,
    required int? lastInterstitialMs,
  }) {
    if (askedFor == version) return false;
    if (launches < minLaunches) return false;
    if (firstDay == null || firstDay == _day(now)) return false;
    if (openedAt == null || now.difference(openedAt) < warmUp) return false;
    if (lastInterstitialMs != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastInterstitialMs)) < adQuiet) {
      return false;
    }
    return true;
  }

  Future<bool> _ask(SharedPreferences p, {required Duration delay}) async {
    final store = InAppReview.instance;
    if (!await store.isAvailable()) return false;
    await p.setString(_kAskedFor, version);
    await Future<void>.delayed(delay);
    await store.requestReview();
    return true;
  }
}
