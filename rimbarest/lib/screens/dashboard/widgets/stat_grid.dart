import 'package:flutter/material.dart';

import '../../../widgets/app_widgets.dart';
import '../../../theme/app_theme.dart';

class StatGrid extends StatelessWidget {
  final Map<String, dynamic>? metrics;

  const StatGrid({
    super.key,
    this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    // 🌟 Ambil Map target secara aman dan bersihkan sintaksis ternary yang salah
    final Map<String, dynamic> targetData =
        (metrics != null && metrics!['currentReadings'] is Map)
            ? Map<String, dynamic>.from(metrics!['currentReadings'] as Map)
            : (metrics ?? {});

    // 🌟 Fungsi pembantu ekstraksi nilai sensor
    String formatMetric(String primaryKey, String fallbackKey) {
      final rawValue = targetData[primaryKey] ?? targetData[fallbackKey];
      if (rawValue == null) return '0';

      final parsedNum = num.tryParse(rawValue.toString());
      return parsedNum?.toString() ?? '0';
    }

    // Ekstraksi nilai sensor dengan pengaman
    final pm25Value = formatMetric('pm25', 'pm25');
    final pm10Value = formatMetric('pm10', 'pm10');
    final tempValue = formatMetric('temperature', 'suhu');
    final humValue = formatMetric('humidity', 'kelembapan');

    // Ekstraksi status secara aman
    final pm25Status = targetData['pm25Status']?.toString() ?? 'NORMAL';
    final pm10Status = targetData['pm10Status']?.toString() ?? 'NORMAL';

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            StatCard(
              label: 'Partikulat PM2.5',
              value: pm25Value,
              unit: ' µg/m³',
              icon: Icons.grain_rounded,
              status: pm25Status,
              accentColor: _getStatusColor(pm25Status),
              bgColor: AppTheme.bgCard,
              borderColor: AppTheme.borderSoft,
              trend: targetData['pm25Trend']?.toString() ?? 'Stabil',
              trendUp: targetData['pm25TrendUp'] == true,
            ),
            StatCard(
              label: 'Partikulat PM10',
              value: pm10Value,
              unit: ' µg/m³',
              icon: Icons.scatter_plot_rounded,
              status: pm10Status,
              accentColor: _getStatusColor(pm10Status),
              bgColor: AppTheme.bgCard,
              borderColor: AppTheme.borderSoft,
              trend: targetData['pm10Trend']?.toString() ?? 'Stabil',
              trendUp: targetData['pm10TrendUp'] == true,
            ),
            StatCard(
              label: 'Suhu Udara',
              value: tempValue,
              unit: '°C',
              icon: Icons.thermostat_rounded,
              status: 'NORMAL',
              accentColor: AppTheme.primary,
              bgColor: AppTheme.bgCard,
              borderColor: AppTheme.borderSoft,
              trend: 'Suhu Sekitar',
              trendUp: false,
            ),
            StatCard(
              label: 'Kelembapan',
              value: humValue,
              unit: '%',
              icon: Icons.water_drop_rounded,
              status: 'NORMAL',
              accentColor: Colors.blue,
              bgColor: AppTheme.bgCard,
              borderColor: AppTheme.borderSoft,
              trend: 'Kondisi Udara',
              trendUp: false,
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'KRITIS':
      case 'BAHAYA':
        return Colors.red;
      case 'WASPADA':
        return AppTheme.warning;
      case 'NORMAL':
      default:
        return AppTheme.primary;
    }
  }
}
