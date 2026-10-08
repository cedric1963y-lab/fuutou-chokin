import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ledger.dart';

/// 端末内（UserDefaults）だけに保存する。サーバーには送らない。
abstract class LedgerRepository {
  Future<Ledger?> read();
  Future<void> write(Ledger ledger);
  Future<void> wipe();
}

class PrefsLedgerRepository implements LedgerRepository {
  static const _key = 'fuutou.ledger.v1';

  @override
  Future<Ledger?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Ledger.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(Ledger ledger) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ledger.toJson()));
  }

  @override
  Future<void> wipe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// 撮影用・テスト用。保存しない。
class MemoryLedgerRepository implements LedgerRepository {
  MemoryLedgerRepository([this._ledger]);
  Ledger? _ledger;

  @override
  Future<Ledger?> read() async => _ledger;

  @override
  Future<void> write(Ledger ledger) async => _ledger = ledger;

  @override
  Future<void> wipe() async => _ledger = null;
}
