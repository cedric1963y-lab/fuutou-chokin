import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'monetization/ad_service.dart';
import 'persistence/ledger_repository.dart';
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
      showcase: show,
    ));
    return;
  }

  final controller = LedgerController(PrefsLedgerRepository());
  final ads = AdService();
  runApp(FuutouApp(controller: controller, ads: ads));
  controller.load();
  WidgetsBinding.instance.addPostFrameCallback((_) => ads.start());
}
