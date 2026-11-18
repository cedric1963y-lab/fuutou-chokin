import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/csv_export.dart';
import '../domain/ledger.dart';

/// 支出の記録と、締めた期間の結果をCSVにして共有シートで渡す（プレミアム）。
Future<void> shareCsv(BuildContext context, Ledger ledger) async {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box != null && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final spends = File('${dir.path}/封筒貯金_支出_$stamp.csv');
    final periods = File('${dir.path}/封筒貯金_期間ごと_$stamp.csv');
    await spends.writeAsString(spendsCsv(ledger), encoding: utf8);
    await periods.writeAsString(periodsCsv(ledger), encoding: utf8);
    await SharePlus.instance.share(ShareParams(
      files: [
        XFile(spends.path, mimeType: 'text/csv'),
        XFile(periods.path, mimeType: 'text/csv'),
      ],
      subject: '封筒貯金の記録（CSV）',
      sharePositionOrigin: origin,
    ));
  } catch (e) {
    messenger.showSnackBar(const SnackBar(content: Text('CSVを書き出せませんでした')));
  }
}
