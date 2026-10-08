import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_ids.dart';

/// 広告の準備（UMP の同意 → ATT → SDK 初期化）と、全画面広告の間隔管理。
///
/// 全画面広告は「給料日の締めのあと」「袋の編集を終えたとき」だけ要求する。
/// 支出の入力では絶対に出さない。
class AdService extends ChangeNotifier {
  AdService({this.enabled = true});

  /// 撮影モードやテストでは false（SDK に触れない）
  final bool enabled;

  static const minGap = Duration(minutes: 4);
  static const warmUp = Duration(seconds: 60);
  static const _lastShownKey = 'fuutou.ads.lastInterstitial';

  bool _starting = false;
  bool _ready = false;
  bool _personalized = false;
  bool _privacyOptionsRequired = false;
  InterstitialAd? _interstitial;
  final DateTime _sessionStart = DateTime.now();

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
    await _tracking();
    await _readPersonalization();
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('AdMob initialize failed: $e');
    }
    _ready = true;
    notifyListeners();
    _loadInterstitial();
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

  void _loadInterstitial() {
    if (!_ready || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: request(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (err) {
          debugPrint('interstitial load failed: ${err.message}');
          _interstitial = null;
        },
      ),
    );
  }

  /// ひと区切りついたときに呼ぶ。間隔があいていて、読み込み済みのときだけ表示。
  Future<void> maybeShowInterstitial() async {
    if (!_ready) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    final now = DateTime.now();
    if (now.difference(_sessionStart) < warmUp) return;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastShownKey);
    if (last != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(last)) < minGap) {
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _loadInterstitial();
      },
    );
    await prefs.setInt(_lastShownKey, now.millisecondsSinceEpoch);
    await ad.show();
  }
}
