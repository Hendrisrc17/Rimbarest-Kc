import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── LightCard ─────────────────────────────────────────────────────────────
class LightCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const LightCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── StatCard ──────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final String status;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final String trend;
  final bool trendUp;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.status,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: accentColor, size: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: value,
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Outfit')),
                TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                        fontFamily: 'Outfit')),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10)),
              const Spacer(),
              Icon(
                trendUp ? Icons.trending_up : Icons.trending_down,
                color: trendUp ? AppTheme.danger : AppTheme.success,
                size: 12,
              ),
              Text(trend,
                  style: TextStyle(
                      color: trendUp ? AppTheme.danger : AppTheme.success,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── NodeRow ───────────────────────────────────────────────────────────────
class NodeRow extends StatelessWidget {
  final String name;
  final String status;
  final String pm;
  final String db;

  const NodeRow({
    super.key,
    required this.name,
    required this.status,
    required this.pm,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;
    Color bg;
    Color border;

    switch (status) {
      case 'warning':
        color = AppTheme.danger;
        icon = Icons.warning_rounded;
        label = 'WASPADA';
        bg = AppTheme.bgDanger;
        border = AppTheme.bdrDanger;
        break;
      case 'offline':
        color = AppTheme.textLight;
        icon = Icons.signal_wifi_off;
        label = 'OFFLINE';
        bg = AppTheme.bgInput;
        border = AppTheme.borderSoft;
        break;
      default:
        color = AppTheme.success;
        icon = Icons.check_circle_rounded;
        label = 'ONLINE';
        bg = AppTheme.bgSuccess;
        border = AppTheme.bdrSuccess;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('PM2.5: $pm µg/m³',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 10)),
                    const SizedBox(width: 8),
                    Text('$db dB',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: border),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ─── SectionHeader ─────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            gradient: LightGradients.primaryGrad,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            Text(subtitle,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ─── TrendChart ────────────────────────────────────────────────────────────
class TrendChart extends StatelessWidget {
  const TrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TrendPainter());
  }
}

class _TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pm25 = [
      32.0,
      28.0,
      35.0,
      42.0,
      38.0,
      24.7,
      22.0,
      19.0,
      24.0,
      30.0,
      45.0,
      67.0,
      55.0,
      40.0,
      35.0,
      28.0,
      24.7
    ];
    final db = [
      55.0,
      58.0,
      62.0,
      65.0,
      70.0,
      72.0,
      64.0,
      58.0,
      55.0,
      60.0,
      68.0,
      78.0,
      72.0,
      65.0,
      60.0,
      56.0,
      62.4
    ];

    _drawLine(canvas, size, pm25, 90.0, AppTheme.danger);
    _drawLine(canvas, size, db, 90.0, AppTheme.primary);

    canvas.drawLine(
        Offset(0, size.height - 16),
        Offset(size.width, size.height - 16),
        Paint()
          ..color = AppTheme.borderSoft
          ..strokeWidth = 0.5);

    const hours = ['00', '04', '08', '12', '16', '20', '24'];
    for (int i = 0; i < hours.length; i++) {
      final x = i * size.width / (hours.length - 1);
      final tp = TextPainter(
        text: TextSpan(
            text: hours[i],
            style: const TextStyle(
                color: AppTheme.textLight, fontSize: 8, fontFamily: 'Outfit')),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height - 1));
    }

    _dot(canvas, 12, 8, AppTheme.danger);
    _label(canvas, 'PM2.5', 20, 8);
    _dot(canvas, 68, 8, AppTheme.primary);
    _label(canvas, 'dB', 76, 8);
  }

  void _drawLine(
      Canvas c, Size s, List<double> data, double maxVal, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * s.width / (data.length - 1);
      final y = (s.height - 18) - (data[i] / maxVal) * (s.height - 28);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    c.drawPath(path, paint);
    final fill = Path.from(path)
      ..lineTo((data.length - 1) * s.width / (data.length - 1), s.height - 18)
      ..lineTo(0, s.height - 18)
      ..close();
    c.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            colors: [color.withValues(alpha: 0.1), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));
  }

  void _dot(Canvas c, double x, double y, Color color) {
    c.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
  }

  void _label(Canvas c, String text, double x, double y) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9,
              fontFamily: 'Outfit')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => false;
}
