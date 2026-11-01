import 'package:flutter/foundation.dart';

/// ホーム画面ウィジェットからの起動先（封筒ID）。
class DeepLinkBus extends ChangeNotifier {
  String? _pendingEnvelopeId;

  String? get pendingEnvelopeId => _pendingEnvelopeId;

  void openEnvelope(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    _pendingEnvelopeId = trimmed;
    notifyListeners();
  }

  void openHome() {
    _pendingEnvelopeId = null;
    notifyListeners();
  }

  /// 消費してクリア。なければ null。
  String? takeEnvelopeId() {
    final id = _pendingEnvelopeId;
    _pendingEnvelopeId = null;
    return id;
  }
}
