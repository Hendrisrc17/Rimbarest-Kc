// File: lib/screens/alert/widgets/alert_app_bar.dart
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class AlertAppBar extends StatelessWidget {
  final int unread;
  final VoidCallback? onMarkAllRead;

  const AlertAppBar({
    super.key,
    required this.unread,
    this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.bgPage,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          const Text(
            'Peringatan',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.danger,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (unread > 0)
          TextButton(
            onPressed: onMarkAllRead,
            child: const Text(
              'Tandai Baca',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
