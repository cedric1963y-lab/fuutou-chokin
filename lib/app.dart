import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'look/kraft_theme.dart';
import 'monetization/ad_service.dart';
import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';
import 'showcase.dart';
import 'state/ledger_controller.dart';

/// 画面のどこからでも状態と広告に届くようにする。
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.controller,
    required this.ads,
    this.showcase,
    required super.child,
  });

  final LedgerController controller;
  final AdService ads;
  final Showcase? showcase;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) =>
      old.controller != controller || old.ads != ads;
}

class FuutouApp extends StatelessWidget {
  const FuutouApp({
    super.key,
    required this.controller,
    required this.ads,
    this.showcase,
  });

  final LedgerController controller;
  final AdService ads;
  final Showcase? showcase;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      ads: ads,
      showcase: showcase,
      child: MaterialApp(
        title: '封筒貯金',
        debugShowCheckedModeBanner: false,
        theme: Kraft.theme(),
        locale: const Locale('ja', 'JP'),
        supportedLocales: const [Locale('ja', 'JP')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (!controller.loaded) {
              return const Scaffold(body: SizedBox.shrink());
            }
            if (controller.needsSetup) return const WelcomeScreen();
            return const HomeShell();
          },
        ),
      ),
    );
  }
}
