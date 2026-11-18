import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../domain/ledger.dart';
import '../domain/yen.dart';

/// App Group / WidgetKit との橋渡し。ウィジェットは無料（課金ゲートなし）。
abstract final class HomeWidgetSync {
  static const appGroupId = 'group.jp.fuutouchokin.app';
  static const widgetKind = 'FuutouEnvelopesWidget';
  static const envelopesKey = 'envelopes_json';
  static const urlScheme = 'fuutouchokin';

  static bool get _supported =>
      !kIsWeb && Platform.isIOS && !Platform.environment.containsKey('FLUTTER_TEST');

  static Future<void> ensureConfigured() async {
    if (!_supported) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('home_widget setAppGroupId: $e');
    }
  }

  static Future<void> publish(Ledger ledger) async {
    if (!_supported) return;
    try {
      await ensureConfigured();
      final rows = ledger.envelopes.map((e) {
        final left = ledger.balanceOf(e);
        final funded = e.isSavings ? e.budget : ledger.fundedIn(e);
        return {
          'id': e.id,
          'name': e.name,
          'tint': e.tint.index,
          'left': left,
          'funded': funded,
          'savings': e.isSavings,
          'leftLabel': yen(left),
        };
      }).toList();
      await HomeWidget.saveWidgetData<String>(envelopesKey, jsonEncode(rows));
      await HomeWidget.updateWidget(name: widgetKind, iOSName: widgetKind);
    } catch (e) {
      debugPrint('home_widget publish: $e');
    }
  }

  static Future<void> clear() async {
    if (!_supported) return;
    try {
      await ensureConfigured();
      await HomeWidget.saveWidgetData<String>(envelopesKey, '[]');
      await HomeWidget.updateWidget(name: widgetKind, iOSName: widgetKind);
    } catch (e) {
      debugPrint('home_widget clear: $e');
    }
  }

  /// `fuutouchokin://envelope/<id>` → id。ホーム起動は null。
  static String? envelopeIdFromUri(Uri? uri) {
    if (uri == null || uri.scheme != urlScheme) return null;
    if (uri.host == 'envelope') {
      if (uri.pathSegments.isNotEmpty) return uri.pathSegments.first;
      final q = uri.queryParameters['id'];
      if (q != null && q.isNotEmpty) return q;
    }
    if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'envelope') {
      return uri.pathSegments[1];
    }
    return null;
  }
}
