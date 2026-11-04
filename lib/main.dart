import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'feedback/rating_ask.dart';
import 'monetization/ad_service.dart';
import 'persistence/ledger_repository.dart';
import 'premium/premium_store.dart';
import 'showcase.dart';
import 'state/ledger_controller.dart';
import 'widget/deep_link_bus.dart';
import 'widget/home_widget_sync.dart';

Future<void> main() async {
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
    // ウィジェット用に App Group へ見本残高を書き込み、WidgetCenter を reload する。
    await show.controller.load();
    runApp(FuutouApp(
      controller: show.controller,
      ads: AdService(enabled: false),
      premium: show.premium,
      showcase: show,
      deepLinks: DeepLinkBus(),
    ));
    return;
  }

  final controller = LedgerController(PrefsLedgerRepository());
  final ads = AdService();
  final premium = PremiumStore();
  final deepLinks = DeepLinkBus();
  // プレミアム（広告なし）ならバナーも全画面広告も止める
  premium.addListener(() => ads.adFree = premium.unlocked);
  const rating = RatingAsk();

  unawaited(HomeWidgetSync.ensureConfigured());
  unawaited(_wireWidgetLaunches(deepLinks));

  runApp(FuutouApp(
    controller: controller,
    ads: ads,
    premium: premium,
    rating: rating,
    deepLinks: deepLinks,
  ));
  rating.noteLaunch();
  controller.load();
  premium.start();
  WidgetsBinding.instance.addPostFrameCallback((_) => ads.start());
}

Future<void> _wireWidgetLaunches(DeepLinkBus bus) async {
  void handle(Uri? uri) {
    if (uri == null) return;
    final id = HomeWidgetSync.envelopeIdFromUri(uri);
    if (id != null) {
      bus.openEnvelope(id);
    } else if (uri.scheme == HomeWidgetSync.urlScheme) {
      bus.openHome();
    }
  }

  try {
    handle(await HomeWidget.initiallyLaunchedFromHomeWidget());
  } catch (e) {
    debugPrint('widget initial launch: $e');
  }
  HomeWidget.widgetClicked.listen(handle);
}
