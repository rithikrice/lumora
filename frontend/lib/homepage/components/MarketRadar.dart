// lib/homepage/components/MarketRadar.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lumora/homepage/theme.dart';

class MarketRadar extends StatefulWidget {
  const MarketRadar({super.key});
  @override
  State<MarketRadar> createState() => _MarketRadarState();
}

class _MarketRadarState extends State<MarketRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Market radar visualization',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Market Radar', style: heading(18)),
                Icon(Icons.radar, color: kAccent),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RadarPainter(sweep: _c.value),
                      size: const Size(200, 200),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '• Regulatory changes  • Competitor signals  • Sentiment heatmap',
              style: bodyStyle(13),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweep;
  _RadarPainter({required this.sweep});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = kAccent.withOpacity(0.18);

    final rings = [80.0, 120.0, 160.0];
    for (var r in rings) {
      canvas.drawCircle(center, r / 2, paint);
    }

    // draw dots (static sample)
    final dotPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = kAccent;
    final angles = [0.3, 1.2, 3.0].map((a) => a * pi).toList();
    final radii = [60.0, 90.0, 140.0];
    for (int i = 0; i < angles.length; i++) {
      final pos = Offset(
        center.dx + cos(angles[i]) * radii[i] / 2,
        center.dy + sin(angles[i]) * radii[i] / 2,
      );
      canvas.drawCircle(pos, 6, dotPaint);
    }

    // sweeping arc
    final sweepPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [kAccent.withOpacity(0.18), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: 100))
          ..style = PaintingStyle.fill;
    final angle = sweep * 2 * pi;
    final path =
        Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(
            Rect.fromCircle(center: center, radius: 100),
            angle - 0.3,
            0.6,
            false,
          )
          ..close();
    canvas.drawPath(path, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.sweep != sweep;
}
