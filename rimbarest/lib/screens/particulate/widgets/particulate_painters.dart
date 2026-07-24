import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/particulate_data.dart';

class GaugePainter extends CustomPainter {
  final double value;
  final double numberValue;
  final String unit;
  final String status;
  final Color statusColor;

  GaugePainter(
    this.value, {
    required this.numberValue,
    required this.unit,
    required this.status,
    required this.statusColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.75);
    final radius = size.width * 0.36;

    const start = math.pi;
    const sweep = math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..color = AppTheme.bgInput
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final segments = [
      AppTheme.success,
      AppTheme.warning,
      const Color(0xFFEA580C),
      AppTheme.danger,
    ];

    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + (sweep / 4) * i,
        sweep / 4,
        false,
        Paint()
          ..color = segments[i].withValues(alpha: 0.25)
          ..strokeWidth = 18
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep * value,
      false,
      Paint()
        ..shader = LightGradients.primaryGrad.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final angle = start + sweep * value;
    final needleEnd = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = AppTheme.textPrimary
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      center,
      5,
      Paint()..color = AppTheme.textPrimary,
    );

    _drawText(
      canvas,
      numberValue.toStringAsFixed(1),
      center.dx,
      center.dy + 16,
      32,
      AppTheme.primary,
      FontWeight.w900,
    );

    _drawText(
      canvas,
      unit,
      center.dx,
      center.dy + 36,
      12,
      AppTheme.textMuted,
      FontWeight.w400,
    );

    _drawText(
      canvas,
      status,
      center.dx,
      center.dy + 54,
      11,
      statusColor,
      FontWeight.w800,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    double size,
    Color color,
    FontWeight weight,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          fontFamily: 'Outfit',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.numberValue != numberValue ||
        oldDelegate.status != status;
  }
}

class LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const maxVal = 80.0;

    final paint = Paint()
      ..shader = LightGradients.primaryGrad.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    for (int i = 0; i < trendParticulateData.length; i++) {
      final x = i * size.width / (trendParticulateData.length - 1);
      final y = size.height -
          12 -
          (trendParticulateData[i] / maxVal) * (size.height - 20);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final fill = Path.from(path)
      ..lineTo(size.width, size.height - 12)
      ..lineTo(0, size.height - 12)
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

    for (int i = 0; i < trendParticulateData.length; i++) {
      final x = i * size.width / (trendParticulateData.length - 1);
      final y = size.height -
          12 -
          (trendParticulateData[i] / maxVal) * (size.height - 20);

      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = AppTheme.primary,
      );
    }
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return false;
  }
}

class ParticlePainter extends CustomPainter {
  final double t;

  ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(1337);
    final sourceX = size.width * 0.18;
    final sourceY = size.height * 0.85;

    for (int i = 0; i < 55; i++) {
      final age = (t + rng.nextDouble()) % 1.0;
      final spread = age * 70 + rng.nextDouble() * 15;
      final drift = age * size.width * 0.65 + rng.nextDouble() * 20 - 10;
      final rise = age * size.height * 0.75;

      final x = sourceX + drift + rng.nextDouble() * spread - spread / 2;
      final y = sourceY - rise;

      if (x < 0 || x > size.width || y < 0 || y > size.height) continue;

      final color = Color.lerp(
        AppTheme.primary,
        AppTheme.secondary,
        age,
      )!
          .withValues(alpha: (1.0 - age) * 0.5);

      canvas.drawCircle(
        Offset(x, y),
        1.5 + age * 2,
        Paint()..color = color,
      );
    }

    canvas.drawCircle(
      Offset(sourceX, sourceY),
      7,
      Paint()..color = AppTheme.danger.withValues(alpha: 0.8),
    );

    canvas.drawCircle(
      Offset(sourceX, sourceY),
      11,
      Paint()
        ..color = AppTheme.danger.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
