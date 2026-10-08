import 'package:flutter/material.dart';

import 'kraft_theme.dart';

/// 大きなコイン（貯金の合計の横に置く）。
class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFF2CF6E), Kraft.coin, Kraft.coinDeep],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 3),
            blurRadius: 5,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.74,
        height: size * 0.74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF7E3A4).withValues(alpha: 0.8), width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          '¥',
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF8A5F12),
            height: 1,
          ),
        ),
      ),
    );
  }
}
