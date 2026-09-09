// File: lib/screens/auth_gate_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool showLogin = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void openRegister() {
    setState(() => showLogin = false);
  }

  void openLogin() {
    setState(() => showLogin = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Stack(
        children: [
          // Dekorasi Lingkaran Latar Belakang (Glow)
          Positioned(
            top: -80,
            left: -60,
            child: _blurCircle(AppTheme.primary),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _blurCircle(AppTheme.secondary),
          ),
          SafeArea(
            child: FadeTransition(
              opacity:
                  _fadeAnimation, // Animasi fade-in awal saat screen dimuat
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                // Berpindah secara dinamis antara Login dan Register Screen
                child: showLogin
                    ? LoginScreen(
                        key: const ValueKey("login"),
                        onRegister: openRegister,
                      )
                    : RegisterScreen(
                        key: const ValueKey("register"),
                        onLogin: openLogin,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(Color color) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.10),
      ),
    );
  }
}
