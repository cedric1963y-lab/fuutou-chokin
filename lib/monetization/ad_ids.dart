import 'package:flutter/foundation.dart';

/// AdMob の ID。release ビルドだけ本番、それ以外（debug / profile / test）は
/// Google 公式のテスト用 ID。アプリ ID（GADApplicationIdentifier）は
/// ios/Flutter/Debug.xcconfig と Release.xcconfig で切り替える。
abstract final class AdIds {
  static const iosAppProd = 'ca-app-pub-5342568663681412~2258671636';
  static const iosBannerProd = 'ca-app-pub-5342568663681412/9308215586';
  static const iosInterstitialProd = 'ca-app-pub-5342568663681412/2555194263';

  static const iosAppTest = 'ca-app-pub-3940256099942544~1458002511';
  static const iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const iosInterstitialTest = 'ca-app-pub-3940256099942544/4411468910';

  static bool get production => kReleaseMode;

  static String get banner => production ? iosBannerProd : iosBannerTest;

  static String get interstitial =>
      production ? iosInterstitialProd : iosInterstitialTest;
}
