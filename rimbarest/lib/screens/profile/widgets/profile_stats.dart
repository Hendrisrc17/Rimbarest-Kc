// File: lib/screens/profile/widgets/profile_stats.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ProfileStats extends StatelessWidget {
  final Map<String, dynamic>? summary;
  final int?
      fallbackNotifCount; // Tambahkan parameter opsional untuk sinkronisasi live data notifikasi

  const ProfileStats({
    super.key,
    required this.summary,
    this.fallbackNotifCount,
  });

  @override
  Widget build(BuildContext context) {
    // Membaca jumlah notifikasi secara toleran dari dashboard summary maupun list aktif screen
    final int unreadNotif = summary?["unreadNotifications"] ??
        summary?["unread_notifications"] ??
        summary?["total_notifications"] ??
        fallbackNotifCount ??
        0;

    final stats = [
      {
        "label": "Node Aktif",
        "value": "${summary?["online_nodes"] ?? summary?["onlineNodes"] ?? 0}",
        "color": AppTheme.primary,
      },
      {
        "label": "Log",
        "value":
            "${summary?["total_detections"] ?? summary?["totalDetections"] ?? 0}",
        "color": AppTheme.secondary,
      },
      {
        "label": "Alert",
        "value": "${summary?["total_alerts"] ?? summary?["totalAlerts"] ?? 0}",
        "color": AppTheme.danger,
      },
      {
        "label": "Notif",
        "value": "$unreadNotif",
        "color": const Color(0xFF2ECC71),
      },
    ];

    return Row(
      children: stats.map((s) {
        final color = s["color"] as Color;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s["value"] as String,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  s["label"] as String,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
