// File: lib/screens/audio/widgets/audio_spectrum.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AudioSpectrum extends StatelessWidget {
  final AnimationController waveCtrl;
  final double currentDb;
  final bool isAnomaly;

  const AudioSpectrum({
    super.key,
    required this.waveCtrl,
    required this.currentDb,
    this.isAnomaly = false,
  });

  @override
  Widget build(BuildContext context) {
    final double dbScale = (currentDb / 50.0).clamp(0.2, 3.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnomaly ? AppTheme.danger : AppTheme.borderMedium,
          width: isAnomaly ? 2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAnomaly
                    ? "🚨 SPEKTRUM ANOMALI TERDETEKSI"
                    : "Spektrogram Frekuensi Lingkungan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAnomaly ? AppTheme.danger : AppTheme.textPrimary,
                  fontSize: 13,
                ),
              ),
              if (isAnomaly)
                const Text(
                  "CRITICAL SPEED",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppTheme.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: waveCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: LancipSpectrumPainter(
                    animationValue: waveCtrl.value,
                    dbScale: dbScale,
                    color: isAnomaly ? AppTheme.danger : Colors.blue,
                    isAnomaly: isAnomaly,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LancipSpectrumPainter extends CustomPainter {
  final double animationValue;
  final double dbScale;
  final Color color;
  final bool isAnomaly;

  LancipSpectrumPainter({
    required this.animationValue,
    required this.dbScale,
    required this.color,
    required this.isAnomaly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double centerY = size.height;
    final double step = size.width / 30;

    final int seedOffset = isAnomaly ? DateTime.now().millisecond : 100;
    final math.Random random = math.Random(seedOffset);

    path.moveTo(0, centerY);

    for (int i = 0; i <= 30; i++) {
      final double x = i * step;
      final double speedMultiplier = isAnomaly ? 6.0 : 1.5;
      final double waveFormula =
          math.sin((animationValue * 2 * math.pi * speedMultiplier) + i);
      final double noiseJitter = random.nextDouble() * (isAnomaly ? 25.0 : 5.0);
      final double spikeHeight =
          ((20.0 + noiseJitter) * dbScale) + (waveFormula * 15.0);
      final double boundedHeight = spikeHeight.clamp(4.0, size.height - 5);
      final double y = centerY - boundedHeight;

      if (i % 2 == 0) {
        path.lineTo(x, centerY);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    if (isAnomaly) {
      final fillPaint = Paint()
        ..color = color.withAlpha(40)
        ..style = PaintingStyle.fill;
      path.lineTo(size.width, centerY);
      path.lineTo(0, centerY);
      canvas.drawPath(path, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LancipSpectrumPainter oldDelegate) => true;
}
