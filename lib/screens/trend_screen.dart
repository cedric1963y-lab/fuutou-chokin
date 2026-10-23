import 'dart:math';

import 'package:flutter/material.dart';

import '../app.dart';
import '../domain/ledger.dart';
import '../domain/trend.dart';
import '../domain/yen.dart';
import '../look/kraft_paper.dart';
import '../look/kraft_theme.dart';
import '../state/ledger_controller.dart';

/// 期間（給料日〜次の給料日の前日）ごとの支出の推移（プレミアム）。
class TrendScreen extends StatefulWidget {
  const TrendScreen({super.key, this.initialEnvelope});
  final String? initialEnvelope;

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  String? _envelope;

  @override
  void initState() {
    super.initState();
    _envelope = widget.initialEnvelope;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context).controller;
    return Scaffold(
      appBar: AppBar(title: const Text('月ごとのグラフ'), backgroundColor: Kraft.paper),
      body: KraftPaper(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) {
            final l = c.ledger;
            final names = trendEnvelopeNames(l);
            if (_envelope != null && !names.contains(_envelope)) _envelope = null;
            final bars = spendingTrend(l, envelopeName: _envelope, maxPeriods: 12);
            final chartBars = bars.length > 6 ? bars.sublist(bars.length - 6) : bars;
            final closed = bars.where((b) => !b.current).toList();
            final avg = closed.isEmpty
                ? null
                : (closed.fold(0, (s, b) => s + b.spent) / closed.length).round();
            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
              children: [
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _chip('ぜんぶ', _envelope == null, () => setState(() => _envelope = null)),
                      for (final n in names)
                        _chip(n, _envelope == n, () => setState(() => _envelope = n)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_envelope == null ? '使った金額（貯金以外の合計）' : '「$_envelope」で使った金額',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _legend(Kraft.tint(_tintFor(c, _envelope)), '支出'),
                            const SizedBox(width: 12),
                            _legend(Kraft.stamp, '予算', line: true),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 220,
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _BarsPainter(
                              chartBars,
                              Kraft.tint(_tintFor(c, _envelope)),
                            ),
                          ),
                        ),
                        if (closed.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('給料日に締めると、期間ごとの棒が増えていきます。',
                                style: TextStyle(fontSize: 12, color: Kraft.inkSoft)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (avg != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text('締めた期間の平均 ${yen(avg)}（${closed.length}回分）',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = bars.length - 1; i >= 0; i--) ...[
                        if (i < bars.length - 1) const Divider(height: 1),
                        _row(bars[i]),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static EnvelopeTint _tintFor(LedgerController c, String? name) {
    for (final e in c.ledger.envelopes) {
      if (e.name == name) return e.tint;
    }
    return EnvelopeTint.kraft;
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: const Color(0xFFE2C79C),
          backgroundColor: const Color(0xFFFBF6EC),
          showCheckmark: false,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: Kraft.ink),
        ),
      );

  Widget _legend(Color color, String label, {bool line = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: line ? 3 : 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11.5, color: Kraft.inkSoft)),
        ],
      );

  Widget _row(PeriodBar b) {
    final over = b.budget > 0 && b.spent > b.budget;
    return ListTile(
      dense: true,
      title: Text('${md(b.start)}〜${md(b.end)}${b.current ? '（今の期間）' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text('予算 ${yen(b.budget)}', style: const TextStyle(fontSize: 12, color: Kraft.inkSoft)),
      trailing: Text(yen(b.spent),
          style: TextStyle(fontFamily: Kraft.display, fontSize: 17, color: over ? Kraft.stamp : Kraft.ink)),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.bars, this.color);
  final List<PeriodBar> bars;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const labelH = 34.0;
    const topPad = 18.0;
    final chartH = size.height - labelH - topPad;
    final top = bars.fold(1, (m, b) => max(m, max(b.spent, b.budget)));
    final slot = size.width / bars.length;
    final barW = min(38.0, slot * 0.56);
    final base = topPad + chartH;
    final hsl = HSLColor.fromColor(color);
    final edge = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();

    canvas.drawLine(Offset(0, base), Offset(size.width, base),
        Paint()
          ..color = Kraft.line
          ..strokeWidth = 1.2);

    for (var i = 0; i < bars.length; i++) {
      final b = bars[i];
      final cx = slot * i + slot / 2;
      final h = chartH * b.spent / top;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, base - h, barW, h),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = b.current ? color.withValues(alpha: 0.55) : color);
      canvas.drawRRect(
          rect,
          Paint()
            ..color = edge
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
      if (b.budget > 0) {
        final by = base - chartH * b.budget / top;
        canvas.drawLine(Offset(cx - barW / 2 - 5, by), Offset(cx + barW / 2 + 5, by),
            Paint()
              ..color = Kraft.stamp
              ..strokeWidth = 2.4
              ..strokeCap = StrokeCap.round);
      }
      _text(canvas, _short(b.spent), Offset(cx, base - h - 15), 10.5, Kraft.ink, bold: true);
      _text(canvas, '${b.start.month}/${b.start.day}〜', Offset(cx, base + 5), 10.5, Kraft.inkSoft);
      if (b.current) _text(canvas, '今', Offset(cx, base + 19), 10, Kraft.stamp, bold: true);
    }
  }

  static String _short(int v) {
    if (v >= 10000) {
      final man = v / 10000;
      return '${man >= 10 ? man.round() : man.toStringAsFixed(1)}万';
    }
    return yen(v).replaceFirst('¥', '');
  }

  void _text(Canvas canvas, String s, Offset center, double size, Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: size, color: color, fontWeight: bold ? FontWeight.w800 : FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) => old.bars != bars || old.color != color;
}
