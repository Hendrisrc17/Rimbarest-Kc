import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../auth/auth_service.dart';
import '../../auth_gate_screen.dart';

class DashboardAppBar extends StatelessWidget {
  final AnimationController pulse;

  const DashboardAppBar({
    super.key,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 96,
      pinned: true,
      floating: true,
      backgroundColor: AppTheme.bgPage,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LightGradients.primaryGrad,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.forest_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 9),
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RimbaRest',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Bangka Belitung',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // 🌟 PERBAIKAN: Bungkus dengan Center agar container fleksibel terhadap tinggi AppBar
        Center(
          child: AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Opacity(
              opacity: 0.3 + (pulse.value * 0.7),
              child: Container(
                // 🌟 PERBAIKAN: Kecilkan margin vertikal agar tidak mendesak batas atas/bawah
                margin: const EdgeInsets.only(right: 4, top: 4, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bgSuccess,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.bdrSuccess),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LiveDot(),
                    SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.account_circle_outlined,
            color: AppTheme.textMuted,
          ),
          onPressed: () async {
            final isLoggedIn = await AuthService.isLoggedIn();

            if (!context.mounted) return;

            if (isLoggedIn) {
              final navState =
                  context.findAncestorStateOfType<NavigatorState>();
              if (navState != null) {
                DefaultTabController.of(context).animateTo(5);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          "Silakan gunakan menu navigasi bawah untuk membuka Profil.")),
                );
              }
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthGateScreen()),
              );
            }
          },
        ),
      ],
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 5,
      height: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.success,
        ),
      ),
    );
  }
}
