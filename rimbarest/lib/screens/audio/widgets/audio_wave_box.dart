// File: lib/screens/audio/widgets/audio_wave_box.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AudioWaveBox extends StatelessWidget {
  final AnimationController waveCtrl;
  final AnimationController pulseCtrl;
  final double currentDb;

  const AudioWaveBox({
    super.key,
    required this.waveCtrl,
    required this.pulseCtrl,
    required this.currentDb,
  });

  @override
  Widget build(BuildContext context) {
    // Normalisasi desibel (dB) menjadi skala pengali tinggi gelombang
    final double waveScale = (currentDb / 50.0).clamp(0.3, 3.0);

    return Container(
      height: 140,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // 🌟 Latar navy gelap ala osiloskop (bukan hitam pekat lagi)
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderMedium, width: 1.5),
      ),
      child: Stack(
        children: [
          // 1. Grid latar belakang (garis tipis kotak-kotak)
          const Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // 2. Garis ambang batas putus-putus (referensi baseline)
          const Positioned.fill(
            child: CustomPaint(painter: _ThresholdLinePainter()),
          ),

          // 3. Gelombang audio bergaya "spike" tajam berwarna emas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: waveCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SpikeWavePainter(
                    animationValue: waveCtrl.value,
                    waveScale: waveScale,
                    color: const Color(0xFFF5C518), // kuning emas
                  ),
                );
              },
            ),
          ),

          // 4. Indikator Teks Real-Time Angka Desibel di Pojok Kanan Atas
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentDb > 65.0
                            ? AppTheme.danger
                            : AppTheme.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (currentDb > 65.0
                                    ? AppTheme.danger
                                    : AppTheme.success)
                                .withValues(alpha: pulseCtrl.value * 0.6),
                            blurRadius: 6,
                            spreadRadius: pulseCtrl.value * 3,
                          )
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  "${currentDb.toStringAsFixed(1)} dB",
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🌟 Grid osiloskop tipis di latar belakang, mirip milimeter block.
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    const double step = 22;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

/// 🌟 Garis horizontal putus-putus (baseline/ambang batas) seperti referensi.
class _ThresholdLinePainter extends CustomPainter {
  const _ThresholdLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEC4899).withValues(alpha: 0.75)
      ..strokeWidth = 1.2;

    final double y = size.height * 0.42;
    const double dashWidth = 5;
    const double dashSpace = 4;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _ThresholdLinePainter oldDelegate) => false;
}

/// 🌟 Gelombang audio tajam (zig-zag/spike), dengan pola "tenang -> meledak
/// -> tenang lagi" yang bergeser seiring waktu, meniru tampilan waveform
/// editor audio pada referensi gambar.
class _SpikeWavePainter extends CustomPainter {
  final double animationValue;
  final double waveScale;
  final Color color;

  _SpikeWavePainter({
    required this.animationValue,
    required this.waveScale,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double centerY = size.height * 0.55;
    final path = Path();
    path.moveTo(0, centerY);

    const int points = 140;
    final double stepX = size.width / points;

    // Seed tetap supaya bentuk "derau" di tiap posisi X konsisten antar
    // frame; yang bergerak hanya amplop (envelope) amplitudonya lewat
    // animationValue, sehingga wave terlihat "berjalan" secara halus.
    final math.Random rng = math.Random(7);

    for (int i = 0; i <= points; i++) {
      final double progress = i / points;
      final double shifted = (progress + animationValue) % 1.0;

      // Amplop amplitude: tenang di awal & akhir, meledak di tengah,
      // meniru pola pada gambar referensi.
      final double envelope =
          (math.sin(shifted * math.pi * 1.3).abs()).clamp(0.05, 1.0);

      final double jitter = (rng.nextDouble() * 2 - 1);
      final double amp = 5 + envelope * 46 * waveScale;
      final double y = centerY + jitter * amp * (i.isEven ? 1 : -1);

      path.lineTo(i * stepX, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpikeWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.waveScale != waveScale;
  }
}
