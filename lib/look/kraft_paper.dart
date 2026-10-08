import 'dart:math';

import 'package:flutter/material.dart';

import 'kraft_theme.dart';

/// クラフト紙の地紋（細い繊維と小さな斑点）。毎回同じ模様になるよう種を固定。
class KraftPaper extends StatelessWidget {
  const KraftPaper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _FiberPainter(),
      child: child,
    );
  }
}

class _FiberPainter extends CustomPainter {
  const _FiberPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Kraft.paper, Kraft.paperDeep],
        ).createShader(rect),
    );
    final rnd = Random(11);
    final fiber = Paint()
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    final count = (size.width * size.height / 900).clamp(200, 2400).toInt();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final a = rnd.nextDouble() * pi;
      final l = 3 + rnd.nextDouble() * 10;
      fiber.color = (rnd.nextBool()
              ? const Color(0xFF8A6A45)
              : const Color(0xFFFFF7E8))
          .withValues(alpha: 0.10 + rnd.nextDouble() * 0.12);
      canvas.drawLine(
          Offset(x, y), Offset(x + cos(a) * l, y + sin(a) * l), fiber);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
