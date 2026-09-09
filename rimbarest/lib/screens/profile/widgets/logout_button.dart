// File: lib/screens/profile/widgets/logout_button.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const LogoutButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 FIX UTAMA: Menggunakan Card + InkWell untuk memberikan efek ripple material design yang premium
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: AppTheme.danger
          .withValues(alpha: 0.1), // Efek merah soft transparan yang sah
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppTheme.danger.withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.danger.withValues(alpha: 0.15),
        highlightColor: AppTheme.danger.withValues(alpha: 0.05),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppTheme.danger,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                "Keluar Akun",
                style: TextStyle(
                  color: AppTheme.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
