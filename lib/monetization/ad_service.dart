import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_ids.dart';

/// 広告の準備（UMP の同意 → ATT → SDK 初期化）と、全画面広告の間隔管理。
///
/// 全画面広告は「給料日の締めのあと」「袋の編集を終えたとき」だけ要求する。
/// 支出の入力では絶対に出さない。
///
/// 全画面広告は起動時には読み込まない。出す可能性のある画面（給料日の締め・
/// 袋の編集）を開いたときに [prepareInterstitial] で読み込む。
/// 起動のたびに読み込んで出さずに捨てると、表示率（表示/マッチ）が下がるため。
class AdService extends ChangeNotifier {
  AdService({this.enabled = true});

  /// 撮影モードやテストでは false（SDK に触れない）
  final bool enabled;

  static const minGap = Duration(minutes: 4);
  static const warmUp = Duration(seconds: 60);
  static const _lastShownKey = 'fuutou.ads.lastInterstitial';

  /// 読み込んだ全画面広告の有効期限（SDK 上は1時間）より少し短め
  static const maxAge = Duration(minutes: 55);

  bool _starting = false;
  bool _ready = false;
  bool _personalized = false;
  bool _privacyOptionsRequired = false;
  InterstitialAd? _interstitial;
  DateTime? _interstitialLoadedAt;
  bool _interstitialLoading = false;
  bool _wantInterstitial = false;
  bool _showing = false;
  final DateTime _sessionStart = DateTime.now();

  bool _adFree = false;

  /// プレミアム購入済みなら true。バナーも全画面広告も出さない。
  bool get adFree => _adFree;
  set adFree(bool v) {
    if (_adFree == v) return;
    _adFree = v;
    if (v) {
      _interstitial?.dispose();
      _interstitial = null;
      _interstitialLoadedAt = null;
      _wantInterstitial = false;
    }
    notifyListeners();
  }

  bool get ready => _ready;
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  bool get _platformOk =>
      enabled &&
      !kIsWeb &&
      Platform.isIOS &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  /// 最初のフレームのあとに呼ぶ。
  Future<void> start() async {
    if (!_platformOk || _starting) return;
    _starting = true;
    await _consent();
    await _readPersonalization();
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('AdMob initialize failed: $e');
    }
    // ATT の回答を待たずにバナーを読み込む（未回答・拒否は非パーソナライズ）。
    _ready = true;
    notifyListeners();
    // 起動直後に締め・袋の編集の画面が開かれていたら、ここで読み込む
    if (_wantInterstitial) _loadInterstitial();
    await _tracking();
    await _readPersonalization();
  }

  AdRequest request() => AdRequest(nonPersonalizedAds: !_personalized);

  Future<void> _consent() async {
    final done = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((err) {
              if (err != null) debugPrint('UMP form: ${err.message}');
            });
          } catch (e) {
            debugPrint('UMP form skipped: $e');
          }
          if (!done.isCompleted) done.complete();
        },
        (err) {
          debugPrint('UMP update failed: ${err.message}');
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
    } catch (e) {
      debugPrint('UMP skipped: $e');
    }
  }

  Future<void> _tracking() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // ダイアログが前の表示と重ならないよう少し待つ
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('ATT skipped: $e');
    }
  }

  Future<void> _readPersonalization() async {
    try {
      final privacy =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      _privacyOptionsRequired =
          privacy == PrivacyOptionsRequirementStatus.required;
      final consent = await ConsentInformation.instance.getConsentStatus();
      final att = await AppTrackingTransparency.trackingAuthorizationStatus;
      _personalized = att == TrackingStatus.authorized &&
          (consent == ConsentStatus.obtained ||
              consent == ConsentStatus.notRequired);
    } catch (e) {
      _personalized = false;
    }
  }

  /// 設定の「広告のプライバシー設定」
  Future<void> showPrivacyOptions() async {
    if (!_platformOk) return;
    try {
      await ConsentForm.showPrivacyOptionsForm((err) {
        if (err != null) debugPrint('privacy options: ${err.message}');
      });
      await _readPersonalization();
      notifyListeners();
    } catch (e) {
      debugPrint('privacy options skipped: $e');
    }
  }

  /// 全画面広告を出す可能性のある画面（給料日の締め・袋の編集）を開いたときに呼ぶ。
  /// 読み込み済み（期限内）なら何もしない。
  void prepareInterstitial() {
    if (!_platformOk || _adFree) return;
    _wantInterstitial = true;
    _loadInterstitial();
  }

  bool get _interstitialExpired {
    final at = _interstitialLoadedAt;
    return at != null && DateTime.now().difference(at) > maxAge;
  }

  void _loadInterstitial() {
    if (!_ready || _adFree || _interstitialLoading) return;
    if (_interstitial != null) {
      if (!_interstitialExpired) return;
      // 期限切れは表示できないので入れ替える
      _interstitial!.dispose();
      _interstitial = null;
      _interstitialLoadedAt = null;
    }
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: request(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          if (_adFree) {
            ad.dispose();
            return;
          }
          _interstitial = ad;
          _interstitialLoadedAt = DateTime.now();
        },
        onAdFailedToLoad: (err) {
          _interstitialLoading = false;
          debugPrint('interstitial load failed: ${err.message}');
          _interstitial = null;
          _interstitialLoadedAt = null;
        },
      ),
    );
  }

  /// ひと区切りついたときに呼ぶ。間隔があいていて、読み込み済みのときだけ表示。
  Future<void> maybeShowInterstitial() async {
    if (!_ready || _adFree || _showing) return;
    // アプリが前面にいないとき（通知センター・別アプリ・ダイアログ表示中など）は出さない
    final life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) return;
    if (_interstitialExpired) {
      // 期限切れは出しても失敗するので捨てる（次に画面を開いたときに読み直す）
      _interstitial?.dispose();
      _interstitial = null;
      _interstitialLoadedAt = null;
      return;
    }
    // 未読み込みならこの回は出さない（ここで読み込むと、出す場面が来ずに捨てられやすい）
    final ad = _interstitial;
    if (ad == null) return;
    final now = DateTime.now();
    if (now.difference(_sessionStart) < warmUp) return;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastShownKey);
    if (last != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(last)) < minGap) {
      return;
    }
    _interstitial = null;
    _interstitialLoadedAt = null;
    // 次は締め・袋の編集の画面を開いたときに読み込む
    _wantInterstitial = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (a) => _showing = true,
      onAdDismissedFullScreenContent: (a) {
        _showing = false;
        a.dispose();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        _showing = false;
        a.dispose();
      },
    );
    await prefs.setInt(_lastShownKey, now.millisecondsSinceEpoch);
    _showing = true;
    try {
      await ad.show();
    } catch (e) {
      _showing = false;
      debugPrint('interstitial show failed: $e');
    }
  }
}
