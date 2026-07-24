// File: lib/screens/main_navigation.dart
import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth_gate_screen.dart';

import 'dashboard/dashboard_screen.dart';
import 'audio/audio_screen.dart';
import 'particulate/particulate_screen.dart';
import 'map/map_screen.dart';
import 'alert/alert_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AudioScreen(),
    ParticulateScreen(),
    MapScreen(),
    AlertScreen(),
    ProfileScreen(),
  ];

  Future<void> _onTap(int idx) async {
    final protectedMenu = idx == 3 || idx == 4 || idx == 5;

    if (protectedMenu) {
      final login = await AuthService.isLoggedIn();

      // 1. KONDISI BELUM LOGIN: Lempar ke AuthGateScreen
      if (!login && mounted) {
        final loggedInNow = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const AuthGateScreen()),
        );

        // Jika setelah dari AuthGate berhasil login, alihkan index ke halaman tersebut
        if (loggedInNow == true && mounted) {
          setState(() => _index = idx);
        }
        return; // Hentikan eksekusi di sini
      }

      // 2. KONDISI SUDAH LOGIN: Langsung pindah tab tanpa memicu penumpukan halaman login
      if (login && mounted) {
        setState(() => _index = idx);
        return; // Hentikan eksekusi di sini
      }
    }

    // Untuk menu non-protected (Dashboard, Audio, Partikulat)
    setState(() => _index = idx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _screens[_index],
        ),
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: const Border(top: BorderSide(color: AppTheme.borderSoft)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(0, Icons.dashboard_rounded, 'Dashboard', false),
              _item(1, Icons.graphic_eq_rounded, 'Audio', false),
              _item(2, Icons.grain_rounded, 'Partikulat', false),
              _item(3, Icons.map_rounded, 'Peta', true),
              _item(4, Icons.notifications_rounded, 'Peringatan', true),
              _item(5, Icons.account_circle_rounded, 'Profil', true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int idx, IconData icon, String label, bool locked) {
    final active = _index == idx;

    return GestureDetector(
      onTap: () => _onTap(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.bgPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active ? Border.all(color: AppTheme.bdrPrimary) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active ? AppTheme.primary : AppTheme.textLight,
                ),
                if (locked)
                  FutureBuilder<bool>(
                    future: AuthService.isLoggedIn(),
                    builder: (context, snapshot) {
                      // Sembunyikan icon gembok secara dinamis jika user telah login
                      if (snapshot.data == true) return const SizedBox.shrink();
                      return const Positioned(
                        right: -7,
                        top: -5,
                        child: Icon(
                          Icons.lock_rounded,
                          size: 9,
                          color: AppTheme.warning,
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: active ? AppTheme.primary : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
