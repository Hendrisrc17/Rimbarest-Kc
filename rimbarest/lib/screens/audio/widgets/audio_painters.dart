import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class WavePainter extends CustomPainter {
  final double t;

  WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppTheme.primary,
          AppTheme.secondary,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final mid = size.height / 2;
    final path = Path();
    final rng = math.Random(42);

    path.moveTo(0, mid);

    for (int i = 0; i < size.width; i++) {
      final phase = (i / size.width + t) * 2 * math.pi;
      final amp = 16 + 20 * rng.nextDouble() * math.sin(i * 0.04).abs();

      path.lineTo(
        i.toDouble(),
        mid + amp * math.sin(phase * 6 + rng.nextDouble()),
      );
    }

    canvas.drawPath(path, paint);

    final fill = Path.from(path)
      ..lineTo(size.width, mid)
      ..lineTo(0, mid)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.12),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

class SpectrumPainter extends CustomPainter {
  final double t;

  SpectrumPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(77);
    const count = 40;
    final barWidth = size.width / count - 1.5;

    for (int i = 0; i < count; i++) {
      final base = rng.nextDouble() * size.height * 0.75;
      final height =
          base * (0.65 + 0.35 * math.sin(i * 0.4 + t * math.pi * 4).abs());
      final x = i * (barWidth + 1.5);
      final color = Color.lerp(
        AppTheme.primary,
        AppTheme.secondary,
        i / count,
      )!;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - height, barWidth, height),
          const Radius.circular(2),
        ),
        Paint()
          ..shader = LinearGradient(
            colors: [
              color,
              color.withValues(alpha: 0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTWH(x, size.height - height, barWidth, height),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(SpectrumPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
