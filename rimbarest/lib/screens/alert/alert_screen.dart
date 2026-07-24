// File: lib/screens/alert/alert_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/auth_service.dart';
import '../../theme/app_theme.dart';
import 'data/alert_data.dart';
import 'widgets/alert_app_bar.dart';
import 'widgets/alert_banner.dart';
import 'widgets/alert_card.dart';
import 'widgets/alert_filter.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController shake;
  Timer? _realtimeTimer;

  List<AlertData> _alerts = [];
  bool _isLoading = true;
  String filter = 'Semua';

  // SET PENYIMPANAN ID YANG SUDAH DIBACA LOKAL HP
  Set<String> _readAlertIds = {};

  @override
  void initState() {
    super.initState();
    shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _loadReadState().then((_) {
      _fetchAlertsData();
    });

    // Polling data backend setiap 3 detik
    _realtimeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _fetchAlertsData(silent: true);
      }
    });
  }

  // BACA DATA DIBACA DARI HP
  Future<void> _loadReadState() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedReadIds = prefs.getStringList('read_alert_ids');
    if (savedReadIds != null) {
      _readAlertIds = savedReadIds.toSet();
    }
  }

  // SIMPAN DATA DIBACA KE HP
  Future<void> _saveReadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_alert_ids', _readAlertIds.toList());
  }

  Future<void> _fetchAlertsData({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final List<dynamic> rawList = await AuthService.fetchAlerts();
      if (mounted) {
        setState(() {
          _alerts = rawList.map((json) {
            final item = AlertData.fromJson(Map<String, dynamic>.from(json));
            // JIKA ID SANG ALERT ADA DI DAFTAR TERBACA HP, PAKSA READ = TRUE
            if (_readAlertIds.contains(item.id)) {
              item.read = true;
            }
            return item;
          }).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  // AKSI MENEKAN "TANDAI BACA"
  void _markAllAsRead() async {
    setState(() {
      for (var alert in _alerts) {
        alert.read = true;
        _readAlertIds.add(alert.id); // Simpan semua ID alert saat ini
      }
    });

    await _saveReadState(); // PERMANENKAN DI STORAGE HP
    await AuthService.markAllAlertsAsRead(); // KIRIM KE BACKEND
  }

  @override
  void dispose() {
    shake.dispose();
    _realtimeTimer?.cancel();
    super.dispose();
  }

  List<AlertData> get filteredAlerts {
    if (filter == 'Semua') {
      return _alerts;
    }

    return _alerts.where((a) {
      final String cat = a.category.toUpperCase();
      final String lvl = a.level.toLowerCase();

      if (filter == 'Kebakaran') {
        return cat.contains('KEBAKARAN');
      }
      if (filter == 'Audio') {
        return cat.contains('AUDIO') || cat.contains('ANCAMAN');
      }
      if (filter == 'Kuota') {
        return cat.contains('KUOTA') || cat.contains('INTERNET');
      }
      if (filter == 'Kritis') {
        return lvl == 'high' || lvl == 'critical';
      }
      if (filter == 'Waspada') {
        return lvl == 'medium' || lvl == 'warning';
      }
      if (filter == 'Info') {
        return lvl == 'low' || lvl == 'info';
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final int unreadCount = _alerts.where((a) => !a.read).length;
    final int criticalCount = _alerts.where((a) {
      final lvl = a.level.toLowerCase();
      return lvl == 'high' || lvl == 'critical';
    }).length;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchAlertsData();
        },
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AlertAppBar(
              unread: unreadCount,
              onMarkAllRead: _markAllAsRead,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AlertBanner(
                    shake: shake,
                    criticalCount: criticalCount,
                    totalCount: _alerts.length,
                  ),
                  const SizedBox(height: 14),
                  AlertFilter(
                    selected: filter,
                    onChanged: (v) => setState(() => filter = v),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filteredAlerts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(30),
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderMedium),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: AppTheme.success, size: 40),
                          SizedBox(height: 10),
                          Text(
                            "Tidak Ada Peringatan Aktif",
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Semua indikator sensing & kuota dalam kondisi normal.",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredAlerts.map((a) => AlertCard(alert: a)),

                  // 🔥 TAMPILAN BERSIH TANPA KARTU REPORT / JARAK EKSTRA
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
