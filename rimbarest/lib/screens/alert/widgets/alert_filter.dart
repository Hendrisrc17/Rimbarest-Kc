// File: lib/screens/alert/widgets/alert_filter.dart
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/alert_data.dart';

class AlertFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const AlertFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 FIX: MENYESUAIKAN KEY MAP WARNA DENGAN KATEGORI NOTIFIKASI BARU
    final colors = <String, Color>{
      'Semua': AppTheme.primary,
      'Kebakaran': AppTheme.danger,
      'Audio': AppTheme.danger,
      'Kuota': AppTheme.warning,
      'Kritis': AppTheme.danger,
      'Waspada': AppTheme.warning,
      'Info': AppTheme.primary,
    };

    final bgs = <String, Color>{
      'Semua': AppTheme.bgPrimary,
      'Kebakaran': AppTheme.bgDanger,
      'Audio': AppTheme.bgDanger,
      'Kuota': AppTheme.bgWarning,
      'Kritis': AppTheme.bgDanger,
      'Waspada': AppTheme.bgWarning,
      'Info': AppTheme.bgPrimary,
    };

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: alertFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final item = alertFilters[i];
          final active = selected == item;

          // 🔥 SAFE FALLBACK KETIKA ITEM TIDAK DITEMUKAN PADA MAP
          final color = colors[item] ?? AppTheme.primary;
          final bg = bgs[item] ?? AppTheme.bgPrimary;

          return GestureDetector(
            onTap: () => onChanged(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? bg : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active
                      ? color.withValues(alpha: 0.4)
                      : AppTheme.borderSoft,
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: active ? color : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
