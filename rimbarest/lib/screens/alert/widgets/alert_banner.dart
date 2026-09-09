// File: lib/screens/alert/widgets/alert_banner.dart
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class AlertBanner extends StatelessWidget {
  final AnimationController shake;
  final int criticalCount;
  final int totalCount;

  const AlertBanner({
    super.key,
    required this.shake,
    this.criticalCount = 0,
    this.totalCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    // 🧠 MENENTUKAN TAMPILAN BERDASARKAN STATUS PERINGATAN KRITIS
    final bool hasCritical = criticalCount > 0;

    final Color bgColor = hasCritical ? AppTheme.bgDanger : AppTheme.bgSuccess;
    final Color borderColor =
        hasCritical ? AppTheme.bdrDanger : AppTheme.bdrSuccess;
    final Color iconColor = hasCritical ? AppTheme.danger : AppTheme.success;
    final IconData iconData = hasCritical
        ? Icons.notification_important_rounded
        : Icons.verified_user_rounded;

    final String titleText = hasCritical
        ? '$criticalCount Peringatan Kritis Aktif'
        : 'Sistem Terpantau Aman';

    final String subText = hasCritical
        ? 'Memerlukan tindakan/pemeriksaan segera di lokasi node'
        : 'Tidak ada anomali atau ancaman terdeteksi saat ini';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🔔 ANIMASI SHAKE HANYA AKTIF SAAT ADA PERINGATAN KRITIS
          if (hasCritical)
            AnimatedBuilder(
              animation: shake,
              builder: (_, child) {
                return Transform.translate(
                  offset: Offset(shake.value * 2 - 1, 0),
                  child: child,
                );
              },
              child: Icon(
                iconData,
                color: iconColor,
                size: 30,
              ),
            )
          else
            Icon(
              iconData,
              color: iconColor,
              size: 30,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subText,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
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
