import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class MapBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFEEF2FF),
    );

    _drawGrid(canvas, size);
    _drawBangka(canvas, size);
    _drawBelitung(canvas, size);
    _drawLabels(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.borderMedium.withValues(alpha: 0.5)
      ..strokeWidth = 0.4;

    for (int i = 0; i < 10; i++) {
      canvas.drawLine(
        Offset(size.width / 10 * i, 0),
        Offset(size.width / 10 * i, size.height),
        gridPaint,
      );

      canvas.drawLine(
        Offset(0, size.height / 10 * i),
        Offset(size.width, size.height / 10 * i),
        gridPaint,
      );
    }
  }

  void _drawBangka(Canvas canvas, Size size) {
    final islandPaint = Paint()..color = const Color(0xFFDDE6FF);

    final borderPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final points = [
      Offset(0.2 * size.width, 0.35 * size.height),
      Offset(0.3 * size.width, 0.10 * size.height),
      Offset(0.5 * size.width, 0.08 * size.height),
      Offset(0.72 * size.width, 0.18 * size.height),
      Offset(0.82 * size.width, 0.30 * size.height),
      Offset(0.80 * size.width, 0.55 * size.height),
      Offset(0.75 * size.width, 0.85 * size.height),
      Offset(0.60 * size.width, 0.92 * size.height),
      Offset(0.40 * size.width, 0.88 * size.height),
      Offset(0.22 * size.width, 0.75 * size.height),
      Offset(0.12 * size.width, 0.60 * size.height),
    ];

    final bangkaPath = Path()..moveTo(points[0].dx, points[0].dy);

    for (final point in points.skip(1)) {
      bangkaPath.lineTo(point.dx, point.dy);
    }

    bangkaPath.close();

    canvas.drawPath(bangkaPath, islandPaint);
    canvas.drawPath(bangkaPath, borderPaint);
  }

  void _drawBelitung(Canvas canvas, Size size) {
    final islandPaint = Paint()..color = const Color(0xFFDDE6FF);

    final borderPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final points = [
      Offset(0.85 * size.width, 0.25 * size.height),
      Offset(0.95 * size.width, 0.30 * size.height),
      Offset(0.97 * size.width, 0.50 * size.height),
      Offset(0.90 * size.width, 0.65 * size.height),
      Offset(0.82 * size.width, 0.60 * size.height),
      Offset(0.80 * size.width, 0.42 * size.height),
    ];

    final belitungPath = Path()..moveTo(points[0].dx, points[0].dy);

    for (final point in points.skip(1)) {
      belitungPath.lineTo(point.dx, point.dy);
    }

    belitungPath.close();

    canvas.drawPath(belitungPath, islandPaint);
    canvas.drawPath(belitungPath, borderPaint);
  }

  void _drawLabels(Canvas canvas, Size size) {
    _drawText(
      canvas,
      'BANGKA',
      size.width * .42,
      size.height * .50,
      11,
      AppTheme.primary.withValues(alpha: 0.25),
    );

    _drawText(
      canvas,
      'BELITUNG',
      size.width * .88,
      size.height * .45,
      8,
      AppTheme.primary.withValues(alpha: 0.2),
    );

    _drawText(
      canvas,
      'LAUT JAWA',
      size.width * .10,
      size.height * .15,
      8,
      AppTheme.secondary.withValues(alpha: 0.3),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    double size,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
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
  bool shouldRepaint(MapBgPainter oldDelegate) => false;
}
