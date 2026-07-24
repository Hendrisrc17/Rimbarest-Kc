// File: lib/screens/dashboard/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../auth/auth_service.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/node_list.dart';
import 'widgets/stat_grid.dart';
import 'widgets/status_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse;
  Timer? _realtimeTimer;

  Map<String, dynamic> _apiData = {};
  bool _isLoadingFirstTime = true;
  bool _isServerOffline = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fetchDashboardData(isFirstLoad: true);

    _realtimeTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _fetchDashboardData(isFirstLoad: false);
      }
    });
  }

  Future<void> _fetchDashboardData({bool isFirstLoad = false}) async {
    if (isFirstLoad && mounted) {
      setState(() {
        _isLoadingFirstTime = true;
      });
    }

    try {
      final data = await AuthService.dashboardSummary();
      if (mounted) {
        setState(() {
          _apiData = data;
          _isServerOffline = false;
          _isLoadingFirstTime = false;
          _errorMessage = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isServerOffline = true;
          _isLoadingFirstTime = false;
          _errorMessage = error.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    pulse.dispose();
    _realtimeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 PERBAIKAN SAKTI: BUKA BUNGKUS OBJEK 'data' KELUARAN MOBILEOK
    final Map<String, dynamic> rawData =
        (_apiData['data'] is Map<String, dynamic>)
            ? _apiData['data']
            : _apiData;

    final summary = rawData['summary'] ?? {};
    final int onlineNodes = summary['onlineNodes'] ?? 0;
    final List<dynamic> latestReadings = rawData['latestReadings'] ?? [];

    // 🔥 AI INSIGHT DIPASTIKAN TIDAK AKAN NULL LAGI KARENA DIBACA DARI rawData!
    final Map<String, dynamic>? aiInsightData = rawData['aiInsight'] != null
        ? Map<String, dynamic>.from(rawData['aiInsight'])
        : null;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchDashboardData(isFirstLoad: false);
        },
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            DashboardAppBar(pulse: pulse),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    const SizedBox(height: 8),
                    if (_errorMessage != null && !_isServerOffline)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppTheme.warning.withAlpha(76)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Gagal terhubung ke backend server.",
                              style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$_errorMessage",
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: () =>
                                  _fetchDashboardData(isFirstLoad: true),
                              child: const Text("Coba Lagi",
                                  style: TextStyle(color: AppTheme.primary)),
                            )
                          ],
                        ),
                      ),
                    StatusBanner(
                      data: rawData,
                      isServerOffline: _isServerOffline,
                    ),
                    const SizedBox(height: 12),
                    const SectionHeader(
                      title: 'Status Real-time',
                      subtitle: 'Semua komponen sistem rimbarest',
                    ),
                    const SizedBox(height: 4),
                    _isLoadingFirstTime
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : StatGrid(metrics: rawData),
                    const SizedBox(height: 12),
                    SectionHeader(
                      title: 'Node Sensor',
                      subtitle: '$onlineNodes titik pemantauan aktif',
                    ),
                    const SizedBox(height: 6),
                    _isLoadingFirstTime
                        ? const Center(child: CircularProgressIndicator())
                        : NodeList(nodes: latestReadings),
                    const SizedBox(height: 12),

                    // 🚀 SEKARANG AI INSIGHT MASUK PRESISI KE KARTU
                    AiInsightCard(insight: aiInsightData),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
