// File: lib/screens/profile/widgets/about_card.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 FIX UTAMA: Mengganti LightCard kustom yang cacat parameter dengan Container standar yang 100% aman
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSoft),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _aboutRow("Versi Aplikasi", "V1.9.5", Icons.info_outline),
          _divider(),
          _aboutRow(
              "Model AI", "DS-CNN & ISOLATION FOREST", Icons.memory_rounded),
          _divider(),
          _aboutRow(
            "Institusi",
            "Universitas Muhammadiyah Bangka Belitung",
            Icons.account_balance_rounded,
          ),
          _divider(),
          _aboutRow("Kontak", "rimbarest@gmail.com", Icons.email_outlined),
        ],
      ),
    );
  }

  Widget _aboutRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            child: Icon(
              icon,
              color: AppTheme.textMuted,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 135,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(
        left: 42,
        right: 14,
      ),
      color: AppTheme.borderSoft,
    );
  }
}
