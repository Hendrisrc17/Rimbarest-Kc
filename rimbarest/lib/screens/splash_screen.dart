// File: lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';
import '../auth/auth_service.dart'; // 🌟 Import AuthService untuk cek session
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoCtrl;

  late AnimationController _rotateCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _pulseAnim;

  bool _showVideo = true;
  bool _videoReady = false;
  bool _logoStarted = false;

  @override
  void initState() {
    super.initState();
    _setupLogoAnimation();
    _setupVideo();
  }

  void _setupVideo() {
    _videoCtrl = VideoPlayerController.asset("assets/videos/splash_logo.MOV");

    _videoCtrl.initialize().then((_) {
      if (!mounted) return;

      setState(() => _videoReady = true);
      _videoCtrl.play();

      _videoCtrl.addListener(() {
        if (!_videoReady || _logoStarted) return;

        final position = _videoCtrl.value.position;
        final duration = _videoCtrl.value.duration;

        if (duration.inMilliseconds > 0 &&
            position.inMilliseconds >= duration.inMilliseconds - 300) {
          _startLogoSplash();
        }
      });
    }).catchError((_) {
      _startLogoSplash();
    });
  }

  void _setupLogoAnimation() {
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOut,
    );

    _scaleAnim = Tween<double>(
      begin: 0.45,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeCtrl,
        curve: Curves.elasticOut,
      ),
    );

    _pulseAnim = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(_pulseCtrl);
  }

  void _startLogoSplash() {
    if (_logoStarted) return;
    _logoStarted = true;

    _videoCtrl.pause();

    setState(() {
      _showVideo = false;
    });

    _rotateCtrl.repeat();
    _pulseCtrl.repeat(reverse: true);
    _fadeCtrl.forward(from: 0);

    // 🚀 PERBAIKAN NAVIGASI ASINKRONUS MENGGUNAKAN POST FRAME CALLBACK AGAR KEBAL LAYAR PUTIH DI RELEASE MODE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () async {
        if (!mounted) return;

        try {
          // 🌟 Mengecek status login user
          final userLoggedIn = await AuthService.isLoggedIn();

          if (!mounted) return;

          if (userLoggedIn) {
            debugPrint("User terautentikasi, masuk ke mode member.");
          } else {
            debugPrint("User tidak terautentikasi, masuk ke mode tamu.");
          }
        } catch (e) {
          debugPrint("🚨 Gagal memuat session login: $e");
        }

        if (!mounted) return;

        // Hapus stack sebelumnya secara bersih agar session sinkron
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainNavigation(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 650),
          ),
          (route) => false,
        );
      });
    });
  }

  @override
  void dispose() {
    _videoCtrl.dispose();
    _rotateCtrl.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showVideo) {
      return _buildVideoSplash();
    }
    return _buildLogoSplash();
  }

  Widget _buildVideoSplash() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _videoReady
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoCtrl.value.size.width,
                    height: _videoCtrl.value.size.height,
                    child: VideoPlayer(_videoCtrl),
                  ),
                ),
              )
            : const CircularProgressIndicator(
                color: Colors.white,
              ),
      ),
    );
  }

  Widget _buildLogoSplash() {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
          Positioned(
            top: -100,
            left: -60,
            child: _glow(AppTheme.primary, 300),
          ),
          Positioned(
            bottom: -90,
            right: -50,
            child: _glow(AppTheme.secondary, 270),
          ),
          ...List.generate(16, (i) => _particle(i)),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ...List.generate(3, (i) {
                            return AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) {
                                return Container(
                                  width: 65.0 + i * 45,
                                  height: 65.0 + i * 45,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha:
                                            0.16 * (3 - i) * _pulseAnim.value,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                          AnimatedBuilder(
                            animation: _rotateCtrl,
                            builder: (_, __) {
                              return Transform.rotate(
                                angle: _rotateCtrl.value * 2 * math.pi,
                                child: CustomPaint(
                                  size: const Size(130, 130),
                                  painter: _ArcPainter(),
                                ),
                              );
                            },
                          ),
                          Container(
                            width: 82,
                            height: 82,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.30),
                                  blurRadius: 25,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                "assets/images/logo.png",
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) {
                                  return const Icon(
                                    Icons.forest_rounded,
                                    color: Colors.white,
                                    size: 42,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LightGradients.primaryGrad.createShader(bounds);
                      },
                      child: const Text(
                        "RIMBAREST",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "BANGKA BELITUNG",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgPrimary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.bdrPrimary),
                      ),
                      child: Text(
                        "Edge Intelligence · Audio · Partikulat",
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primary.withValues(alpha: 0.85),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 54),
                    const SizedBox(
                      width: 210,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        child: LinearProgressIndicator(
                          value: null,
                          backgroundColor: AppTheme.borderMedium,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Menginisialisasi aplikasi...",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _particle(int index) {
    final random = math.Random(index * 77);
    final x = random.nextDouble();
    final y = random.nextDouble();
    final size = random.nextDouble() * 4 + 1;
    final color = index % 2 == 0 ? AppTheme.primary : AppTheme.secondary;

    return Positioned(
      left: MediaQuery.of(context).size.width * x,
      top: MediaQuery.of(context).size.height * y,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          return Opacity(
            opacity: (0.08 + random.nextDouble() * 0.18) * _pulseAnim.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.045)
      ..strokeWidth = 1;

    const gap = 32.0;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0.2, math.pi * 0.85, false, paint);
    canvas.drawArc(rect, math.pi * 1.1, math.pi * 0.55, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
