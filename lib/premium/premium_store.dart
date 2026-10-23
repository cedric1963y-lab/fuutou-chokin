import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 買い切りの「プレミアム」（貯金の目標・CSV書き出し・グラフ・広告なし）。
///
/// 買ったかどうかは端末に保存し、「購入を復元」で App Store に確かめ直す。
/// 今ある機能はプレミアムがなくてもすべて使える。
class PremiumStore extends ChangeNotifier {
  PremiumStore({this.enabled = true, bool unlocked = false}) : _unlocked = unlocked; // ignore: prefer_initializing_formals

  /// 撮影モードやテストでは false（StoreKit に触れない）
  final bool enabled;

  static const productId = 'jp.fuutouchokin.app.premium';
  static const _unlockedKey = 'fuutou.premium.unlocked';

  /// App Store から価格を読めないときの表示
  static const fallbackPrice = '¥300';

  bool _unlocked;
  bool _started = false;
  bool _busy = false;
  bool _pending = false;
  ProductDetails? _product;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Completer<PremiumResult>? _waiting;

  bool get unlocked => _unlocked;

  /// 購入や復元の途中
  bool get busy => _busy;

  /// 「承認と購入のリクエスト」などで保留中
  bool get pending => _pending;
  String get price => _product?.price ?? fallbackPrice;

  bool get _platformOk =>
      enabled &&
      !kIsWeb &&
      Platform.isIOS &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  InAppPurchase get _iap => InAppPurchase.instance;

  /// 起動時に呼ぶ。保存済みの購入を読み、未完了の取引を受け取れるようにする。
  Future<void> start() async {
    if (_started) return;
    _started = true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_unlockedKey) ?? false) {
      _unlocked = true;
      notifyListeners();
    }
    if (!_platformOk) return;
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        debugPrint('purchase stream: $e');
        _finish(PremiumResult.failed);
      },
    );
    unawaited(_loadProduct());
  }

  Future<bool> _loadProduct() async {
    if (_product != null) return true;
    try {
      if (!await _iap.isAvailable()) return false;
      final res = await _iap.queryProductDetails({productId});
      if (res.productDetails.isNotEmpty) {
        _product = res.productDetails.first;
        notifyListeners();
        return true;
      }
      if (res.error != null) debugPrint('product query: ${res.error}');
    } catch (e) {
      debugPrint('product query failed: $e');
    }
    return false;
  }

  Future<PremiumResult> buy() async {
    if (_unlocked) return PremiumResult.unlocked;
    if (!_platformOk) return PremiumResult.unavailable;
    if (_busy) return PremiumResult.busy;
    _setBusy(true);
    if (!await _loadProduct()) {
      _setBusy(false);
      return PremiumResult.unavailable;
    }
    final waiting = _waiting = Completer<PremiumResult>();
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _product!),
      );
      if (!started) _finish(PremiumResult.failed);
    } catch (e) {
      debugPrint('buy failed: $e');
      _finish(PremiumResult.failed);
    }
    return waiting.future;
  }

  /// 「購入を復元」。見つからなければ notFound。
  Future<PremiumResult> restore() async {
    if (!_platformOk) return PremiumResult.unavailable;
    if (_busy) return PremiumResult.busy;
    _setBusy(true);
    final waiting = _waiting = Completer<PremiumResult>();
    try {
      if (!await _iap.isAvailable()) {
        _finish(PremiumResult.unavailable);
      } else {
        await _iap.restorePurchases();
        // 復元できる購入がないときは何も届かないので、少し待って締める
        Future<void>.delayed(const Duration(seconds: 10), () {
          if (identical(_waiting, waiting)) {
            _finish(_unlocked ? PremiumResult.unlocked : PremiumResult.notFound);
          }
        });
      }
    } catch (e) {
      debugPrint('restore failed: $e');
      _finish(PremiumResult.failed);
    }
    return waiting.future;
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID != productId) {
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
        continue;
      }
      switch (p.status) {
        case PurchaseStatus.pending:
          _pending = true;
          notifyListeners();
          _finish(PremiumResult.pending);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grant();
          _finish(PremiumResult.unlocked);
        case PurchaseStatus.canceled:
          _finish(PremiumResult.cancelled);
        case PurchaseStatus.error:
          debugPrint('purchase error: ${p.error}');
          _finish(PremiumResult.failed);
      }
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (e) {
          debugPrint('complete failed: $e');
        }
      }
    }
  }

  Future<void> _grant() async {
    _pending = false;
    if (_unlocked) return;
    _unlocked = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_unlockedKey, true);
  }

  void _finish(PremiumResult r) {
    final w = _waiting;
    _waiting = null;
    _setBusy(false);
    if (w != null && !w.isCompleted) w.complete(r);
  }

  void _setBusy(bool v) {
    if (_busy == v) return;
    _busy = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

enum PremiumResult { unlocked, pending, cancelled, failed, notFound, unavailable, busy }

/// 結果をひとことで（スナックバー用）。cancelled は何も出さない。
String? premiumResultText(PremiumResult r, {bool restoring = false}) => switch (r) {
      PremiumResult.unlocked => restoring ? 'プレミアムを復元しました' : 'プレミアムになりました。ありがとうございます！',
      PremiumResult.pending => '購入の承認待ちです。承認されると自動で使えるようになります',
      PremiumResult.cancelled => null,
      PremiumResult.failed => '購入を完了できませんでした。時間をおいてもう一度お試しください',
      PremiumResult.notFound => '復元できる購入が見つかりませんでした',
      PremiumResult.unavailable => 'App Store につながりません。通信状態を確認してください',
      PremiumResult.busy => null,
    };
