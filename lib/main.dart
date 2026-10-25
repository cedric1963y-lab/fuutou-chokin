import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'feedback/rating_ask.dart';
import 'monetization/ad_service.dart';
import 'persistence/ledger_repository.dart';
import 'premium/premium_store.dart';
import 'showcase.dart';
import 'state/ledger_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/licenses/KiwiMaru-OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Kiwi Maru'], text);
  });
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 撮影モードは debug ビルドだけ。release では dart-define があっても無視する。
  const scene = String.fromEnvironment('SHOWCASE');
  if (!kReleaseMode && scene.isNotEmpty) {
    final show = Showcase.build(scene);
    runApp(FuutouApp(
      controller: show.controller,
      ads: AdService(enabled: false),
      premium: show.premium,
      showcase: show,
    ));
    return;
  }

  final controller = LedgerController(PrefsLedgerRepository());
  final ads = AdService();
  final premium = PremiumStore();
  // プレミアム（広告なし）ならバナーも全画面広告も止める
  premium.addListener(() => ads.adFree = premium.unlocked);
  const rating = RatingAsk();
  runApp(FuutouApp(controller: controller, ads: ads, premium: premium, rating: rating));
  rating.noteLaunch();
  controller.load();
  premium.start();
  WidgetsBinding.instance.addPostFrameCallback((_) => ads.start());
}
