// File: lib/screens/alert/widgets/alert_card.dart
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/alert_data.dart';

class AlertCard extends StatelessWidget {
  final AlertData alert;

  const AlertCard({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    // 🧠 GAYA DIBENTUK BERDASARKAN LEVEL & KATEGORI DATA BACKEND
    final style = _AlertStyle.fromAlert(alert);
    final unread = !alert.read;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unread ? style.border : AppTheme.borderSoft,
          width: unread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: unread
                ? style.color.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AlertIcon(style: style),
                const SizedBox(width: 11),
                Expanded(
                  child: _AlertContent(
                    alert: alert,
                    style: style,
                    unread: unread,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertIcon extends StatelessWidget {
  final _AlertStyle style;

  const _AlertIcon({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        style.icon,
        color: style.color,
        size: 19,
      ),
    );
  }
}

class _AlertContent extends StatelessWidget {
  final AlertData alert;
  final _AlertStyle style;
  final bool unread;

  const _AlertContent({
    required this.alert,
    required this.style,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (unread)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 5, top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.color,
                ),
              ),
            Expanded(
              child: Text(
                alert.title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          alert.desc,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(
              Icons.sensors,
              size: 10,
              color: AppTheme.textLight,
            ),
            const SizedBox(width: 3),
            Text(
              alert.node,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 9,
              ),
            ),
            const Spacer(),
            Text(
              alert.time,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlertStyle {
  final Color color;
  final Color bg;
  final Color border;
  final IconData icon;

  const _AlertStyle({
    required this.color,
    required this.bg,
    required this.border,
    required this.icon,
  });

  // 🎯 SMART STYLE GENERATOR BERDASARKAN KATEGORI & LEVEL NOTIFIKASI
  factory _AlertStyle.fromAlert(AlertData alert) {
    final String cat = alert.category.toUpperCase();
    final String lvl = alert.level.toLowerCase();

    // 1. ANCAMAN AUDIO / SUARA (Chainsaw, Gunshot, dll)
    if (cat.contains('AUDIO') || cat.contains('ANCAMAN')) {
      return const _AlertStyle(
        color: AppTheme.danger,
        bg: AppTheme.bgDanger,
        border: AppTheme.bdrDanger,
        icon: Icons.record_voice_over_rounded,
      );
    }

    // 2. KEBAKARAN / PARTIKULAT (PM2.5 Tinggi, Asap Tebal)
    if (cat.contains('KEBAKARAN') || cat.contains('PARTIKULAT')) {
      return const _AlertStyle(
        color: AppTheme.danger,
        bg: AppTheme.bgDanger,
        border: AppTheme.bdrDanger,
        icon: Icons.local_fire_department_rounded,
      );
    }

    // 3. PERINGATAN KUOTA INTERNET IOT
    if (cat.contains('KUOTA') || cat.contains('INTERNET')) {
      return const _AlertStyle(
        color: AppTheme.warning,
        bg: AppTheme.bgWarning,
        border: AppTheme.bdrWarning,
        icon: Icons.data_saver_on_rounded,
      );
    }

    // 4. FALLBACK BERDASARKAN LEVEL STANDARD
    if (lvl == 'high' || lvl == 'critical') {
      return const _AlertStyle(
        color: AppTheme.danger,
        bg: AppTheme.bgDanger,
        border: AppTheme.bdrDanger,
        icon: Icons.warning_rounded,
      );
    } else if (lvl == 'medium' || lvl == 'warning') {
      return const _AlertStyle(
        color: AppTheme.warning,
        bg: AppTheme.bgWarning,
        border: AppTheme.bdrWarning,
        icon: Icons.grain_rounded,
      );
    }

    return const _AlertStyle(
      color: AppTheme.primary,
      bg: AppTheme.bgPrimary,
      border: AppTheme.borderMedium,
      icon: Icons.info_outline,
    );
  }
}
