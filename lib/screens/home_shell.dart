import 'package:flutter/material.dart';

import '../app.dart';
import '../look/kraft_paper.dart';
import '../monetization/banner_strip.dart';
import 'board_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final show = AppScope.of(context).showcase;
      if (show != null) {
        if (show.startTab != _tab) setState(() => _tab = show.startTab);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final pages = const [BoardScreen(), HistoryScreen(), SettingsScreen()];
    return Scaffold(
      body: KraftPaper(
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (scope.showcase == null) BannerStrip(ads: scope.ads),
          NavigationBar(
            selectedIndex: _tab,
            height: 64,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.mail_outline),
                selectedIcon: Icon(Icons.mail),
                label: '封筒',
              ),
              NavigationDestination(
                icon: Icon(Icons.savings_outlined),
                selectedIcon: Icon(Icons.savings),
                label: '貯金と履歴',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune),
                label: '設定',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
