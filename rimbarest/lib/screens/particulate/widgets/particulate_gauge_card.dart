import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_widgets.dart';
import 'particulate_painters.dart';

class ParticulateGaugeCard extends StatelessWidget {
  final AnimationController gaugeCtrl;
  final double value;
  final String unit;
  final String status;
  final Color statusColor;
  final String nodeName;

  const ParticulateGaugeCard({
    super.key,
    required this.gaugeCtrl,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.nodeName,
  });

  @override
  Widget build(BuildContext context) {
    return LightCard(
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: AnimatedBuilder(
              animation: gaugeCtrl,
              builder: (_, __) {
                return CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: GaugePainter(
                    gaugeCtrl.value,
                    numberValue: value,
                    unit: unit,
                    status: status,
                    statusColor: statusColor,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                color: AppTheme.textMuted,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                nodeName,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
