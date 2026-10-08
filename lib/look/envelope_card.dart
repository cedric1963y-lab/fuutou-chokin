import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/ledger.dart';
import '../domain/yen.dart';
import 'kraft_theme.dart';

/// 茶封筒の形をしたカード。上にふた、真ん中に名札、下に残りの金額。
/// 中のお札（薄い帯）の高さが残りの割合をあらわす。
class EnvelopeCard extends StatelessWidget {
  const EnvelopeCard({
    super.key,
    required this.name,
    required this.tint,
    required this.left,
    required this.funded,
    this.isSavings = false,
    this.caption,
    this.onTap,
    this.onLongPress,
  });

  final String name;
  final EnvelopeTint tint;
  final int left;
  final int funded;
  final bool isSavings;
  final String? caption;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = Kraft.tint(tint);
    final ratio = funded <= 0 ? (left > 0 ? 1.0 : 0.0) : (left / funded).clamp(0.0, 1.0);
    final over = left < 0;
    return Semantics(
      button: onTap != null,
      label: '$name 残り${yen(left)}',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: CustomPaint(
          painter: _EnvelopePainter(color: color, fill: ratio, savings: isSavings),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 42, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NameTag(name: name, savings: isSavings),
                const Spacer(),
                Text(
                  isSavings ? 'たまっている' : (over ? '使いすぎ' : 'のこり'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: over ? Kraft.stamp : Kraft.ink.withValues(alpha: 0.7),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    yen(left),
                    style: TextStyle(
                      fontFamily: Kraft.display,
                      fontSize: 25,
                      height: 1.1,
                      color: over ? Kraft.stamp : Kraft.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption ?? (isSavings ? '毎月 ${yen(funded)} から' : '入れた額 ${yen(funded)}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Kraft.ink.withValues(alpha: 0.72)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NameTag extends StatelessWidget {
  const _NameTag({required this.name, required this.savings});
  final String name;
  final bool savings;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.025,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(1, 2),
              blurRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (savings) ...[
              const _MiniCoin(size: 16),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: Kraft.display,
                  fontSize: 16,
                  color: Kraft.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCoin extends StatelessWidget {
  const _MiniCoin({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Kraft.coin,
        border: Border.all(color: Kraft.coinDeep, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text('¥',
          style: TextStyle(
              fontSize: size * 0.55,
              fontWeight: FontWeight.w800,
              color: Kraft.coinDeep,
              height: 1)),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  _EnvelopePainter({required this.color, required this.fill, required this.savings});

  final Color color;
  final double fill;
  final bool savings;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));

    // 影
    canvas.drawRRect(
      r.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 中のお札（ふたの下から少しのぞく）
    canvas.save();
    canvas.clipRRect(r);
    final hsl = HSLColor.fromColor(color);
    final body = color;
    final dark = hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor();
    final light = hsl.withLightness((hsl.lightness + 0.07).clamp(0.0, 1.0)).toColor();

    canvas.drawRect(Offset.zero & size, Paint()..color = body);

    // 紙の繊維
    final rnd = Random(color.toARGB32());
    final fiber = Paint()..strokeWidth = 0.7;
    for (var i = 0; i < 90; i++) {
      final x = rnd.nextDouble() * w, y = rnd.nextDouble() * h;
      final a = rnd.nextDouble() * pi;
      fiber.color = (rnd.nextBool() ? Colors.white : Colors.black)
          .withValues(alpha: 0.06 + rnd.nextDouble() * 0.06);
      canvas.drawLine(Offset(x, y), Offset(x + cos(a) * 7, y + sin(a) * 7), fiber);
    }

    // 底の折り返し（左右から中央へ）
    final fold = Paint()
      ..color = dark.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final mid = Offset(w / 2, h * 0.62);
    canvas.drawLine(Offset(0, h), mid, fold);
    canvas.drawLine(Offset(w, h), mid, fold);

    // 残りの量のゲージ（右端の細い帯）
    final gaugeH = (h - 56) * fill;
    final gauge = RRect.fromRectAndRadius(
      Rect.fromLTWH(w - 12, h - 10 - gaugeH, 5, gaugeH),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w - 12, 46, 5, h - 56), const Radius.circular(3)),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );
    if (gaugeH > 0) {
      canvas.drawRRect(
        gauge,
        Paint()..color = savings ? Kraft.coinDeep : const Color(0xFF5E7A4C).withValues(alpha: 0.85),
      );
    }

    // ふた
    final flap = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, 10)
      ..quadraticBezierTo(w * 0.5, 54, 0, 10)
      ..close();
    canvas.drawShadow(flap, Colors.black, 2, false);
    canvas.drawPath(flap, Paint()..color = light);
    canvas.drawPath(
      flap,
      Paint()
        ..color = dark.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();

    // 縁
    canvas.drawRRect(
      r,
      Paint()
        ..color = dark.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 封の印（貯金はコイン、ほかは丸い封緘）
    final seal = Offset(w / 2, 31);
    if (savings) {
      canvas.drawCircle(seal, 11, Paint()..color = Kraft.coin);
      canvas.drawCircle(
          seal,
          11,
          Paint()
            ..color = Kraft.coinDeep
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      final tp = TextPainter(
        text: const TextSpan(
            text: '¥',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Kraft.coinDeep)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, seal - Offset(tp.width / 2, tp.height / 2));
    } else {
      canvas.drawCircle(seal, 6, Paint()..color = Kraft.stamp.withValues(alpha: 0.85));
    }
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter old) =>
      old.color != color || old.fill != fill || old.savings != savings;
}

/// 一覧や選択に使う小さな封筒。
class MiniEnvelope extends StatelessWidget {
  const MiniEnvelope({super.key, required this.tint, this.size = 30, this.savings = false});
  final EnvelopeTint tint;
  final double size;
  final bool savings;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.7),
      painter: _MiniPainter(Kraft.tint(tint), savings),
    );
  }
}

class _MiniPainter extends CustomPainter {
  _MiniPainter(this.color, this.savings);
  final Color color;
  final bool savings;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final hsl = HSLColor.fromColor(color);
    final dark = hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * 0.08));
    canvas.drawRRect(r, Paint()..color = color);
    final flap = Path()
      ..moveTo(0, 0)
      ..lineTo(w / 2, h * 0.55)
      ..lineTo(w, 0);
    canvas.drawPath(
        flap,
        Paint()
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1, w * 0.04));
    canvas.drawRRect(
        r,
        Paint()
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1, w * 0.035));
    if (savings) {
      canvas.drawCircle(Offset(w * 0.5, h * 0.62), h * 0.2, Paint()..color = Kraft.coin);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPainter old) => old.color != color;
}
