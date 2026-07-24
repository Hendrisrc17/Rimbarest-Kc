// File: lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../auth/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth_gate_screen.dart';

import 'edit_profile_screen.dart';
import 'models/profile_state.dart';
import 'widgets/about_card.dart';
import 'widgets/notifications_card.dart';
import 'widgets/profile_card.dart';
import 'widgets/profile_settings.dart';
import 'widgets/profile_stats.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;

  Map<String, dynamic>? user;
  Map<String, dynamic>? summary;
  List<dynamic> notifList = [];

  ProfileState profileState = const ProfileState(
    notif: true,
    location: true,
    nightMode: false,
    interval: "5 detik",
  );

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      final isLogin = await AuthService.isLoggedIn();

      if (!isLogin) {
        if (!mounted) return;
        setState(() {
          loading = false;
          user = null;
        });
        return;
      }

      // 🚀 ISOLASI 1: Ambil Data Profile Inti
      Map<String, dynamic> userData = {};
      try {
        final u = await AuthService.getProfile();
        userData = Map<String, dynamic>.from(u["data"] ?? u);
      } catch (e) {
        debugPrint("🚨 [PROFILE ERROR] Gagal di getProfile: $e");
        await AuthService.clearSession();
        if (mounted) setState(() => user = null);
        return;
      }

      // 🚀 ISOLASI 2: Ambil Summary Dashboard
      Map<String, dynamic> summaryData = {};
      try {
        final s = await AuthService.dashboardSummary();
        summaryData = Map<String, dynamic>.from(s["data"] ?? s["summary"] ?? s);
      } catch (e) {
        debugPrint("⚠️ [PROFILE WARN] Gagal di dashboardSummary: $e");
        summaryData = {
          "online_nodes": 0,
          "total_detections": 0,
          "total_alerts": 0
        };
      }

      // 🚀 ISOLASI 3: Ambil Daftar Notifikasi
      List<dynamic> notificationData = [];
      try {
        final n = await AuthService.notifications();
        final rawNotif = n["data"] ?? n;
        if (rawNotif is List) {
          notificationData = rawNotif;
        } else if (rawNotif["notifications"] is List) {
          notificationData = rawNotif["notifications"];
        }
      } catch (e) {
        debugPrint("⚠️ [PROFILE WARN] Gagal di notifications: $e");
        notificationData = [];
      }

      if (!mounted) return;

      // 🚀 FIX UTAMA ANTI MENTAL: Ambil data dan lakukan pengecekan tipe data secara paksa
      final rawNotifVal = userData['notificationEnabled'] ??
          userData['notification_enabled'] ??
          userData['notif'];
      final rawLocationVal = userData['locationEnabled'] ??
          userData['location_enabled'] ??
          userData['location'];

      bool finalNotifStatus = true;
      if (rawNotifVal != null) {
        finalNotifStatus =
            rawNotifVal.toString() == 'true' || rawNotifVal == true;
      }

      bool finalLocationStatus = true;
      if (rawLocationVal != null) {
        finalLocationStatus =
            rawLocationVal.toString() == 'true' || rawLocationVal == true;
      }

      setState(() {
        user = userData;
        summary = summaryData;
        notifList = notificationData;

        profileState = ProfileState(
          notif: finalNotifStatus,
          location: finalLocationStatus,
          nightMode: profileState.nightMode,
          interval: profileState.interval,
        );

        loading = false;
      });
    } catch (e) {
      debugPrint("❌ [CRITICAL PROFILE] Error utama pada loadAll(): $e");

      if (!mounted) return;
      setState(() => loading = false);

      showMsg("Gagal memperbarui data. Cek koneksi server backend kamu.");
    }
  }

  void showMsg(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> saveSetting({
    bool? notif,
    bool? location,
  }) async {
    final nextState = profileState.copyWith(
      notif: notif,
      location: location,
    );

    setState(() {
      profileState = nextState;
    });

    try {
      // 1. Update profil dasar user di tabel User
      final result = await AuthService.updateProfile(
        notificationEnabled: nextState.notif,
        locationEnabled: nextState.location,
      );

      final updated = Map<String, dynamic>.from(result["data"] ?? result);

      final currentToken = await AuthService.getToken();
      if (currentToken != null) {
        await AuthService.saveSession(currentToken, updated);
      }

      // 🚀 2. SINKRONISASI AKTIF KE TABEL DeviceToken VIA API BYPASS
      if (notif != null) {
        try {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            // 🔧 Catatan: Sesuaikan localhost dengan IP Laptop/Hotspot kamu jika ditesting lewat HP Fisik!
            final url =
                Uri.parse('http://10.244.79.151:3000/api/mobile/user/token');
            await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'token': fcmToken,
                'isActive': nextState.notif,
                'userId': updated['id'],
              }),
            );
          }
        } catch (fcmErr) {
          debugPrint(
              "⚠️ [FCM SYNC WARN] Gagal sinkronisasi token status: $fcmErr");
        }
      }

      if (!mounted) return;

      final serverNotifVal = updated['notificationEnabled'] ??
          updated['notification_enabled'] ??
          nextState.notif;
      final serverLocationVal = updated['locationEnabled'] ??
          updated['location_enabled'] ??
          nextState.location;

      setState(() {
        user = updated;
        profileState = ProfileState(
          notif: serverNotifVal.toString() == 'true' || serverNotifVal == true,
          location: serverLocationVal.toString() == 'true' ||
              serverLocationVal == true,
          nightMode: nextState.nightMode,
          interval: nextState.interval,
        );
      });

      showMsg("Pengaturan berhasil disimpan");
    } catch (e) {
      debugPrint("🚨 Gagal menyimpan pengaturan ke Next.js: $e");
      showMsg("Gagal menyimpan pengaturan ke server");

      if (user != null) {
        setState(() {
          profileState = ProfileState.fromUser(user!);
        });
      }
    }
  }

  Future<void> pickPhoto() async {
    try {
      final updated = await ProfileCard.pickAndUploadPhoto();

      if (updated == null) return;
      if (!mounted) return;

      final updatedData = Map<String, dynamic>.from(updated["data"] ?? updated);

      final currentToken = await AuthService.getToken();
      if (currentToken != null) {
        await AuthService.saveSession(currentToken, updatedData);
      }

      setState(() {
        user = updatedData;
      });

      await loadAll();

      showMsg("Foto profil berhasil diperbarui");
    } catch (e) {
      debugPrint("🚨 Gagal upload foto profil: $e");
      showMsg("Gagal memperbarui foto profil");
    }
  }

  Future<void> openEdit() async {
    if (user == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: user!),
      ),
    );

    if (result == true) {
      setState(() => loading = true);
      await loadAll();
    }
  }

  Future<void> logout() async {
    setState(() => loading = true);

    // Nonaktifkan status token dinamis di database saat keluar akun
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final url =
            Uri.parse('http://10.244.79.151:3000/api/mobile/user/token');
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'token': fcmToken,
            'isActive': false,
          }),
        );
      }
    } catch (_) {}

    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGateScreen()),
      (route) => false,
    );
  }

  Future<void> markNotificationRead(int id) async {
    try {
      await AuthService.markNotificationRead(id.toString());
      await loadAll();
    } catch (e) {
      debugPrint("🚨 Gagal menandai notifikasi dibaca: $e");
    }
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgPage,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (user == null) {
      return const AuthGateScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: RefreshIndicator(
        onRefresh: loadAll,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.bgPage,
              surfaceTintColor: Colors.transparent,
              title: const Text(
                "Profil",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: AppTheme.primary,
                  ),
                  onPressed: openEdit,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  ProfileCard(
                    user: user!,
                    onPhotoTap: pickPhoto,
                  ),
                  const SizedBox(height: 16),
                  ProfileStats(
                    summary: summary,
                    fallbackNotifCount: notifList.length,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader("Pengaturan", "Konfigurasi aplikasi"),
                  const SizedBox(height: 10),
                  ProfileSettings(
                    notif: profileState.notif,
                    location: profileState.location,
                    onNotifChanged: (v) => saveSetting(notif: v),
                    onLocationChanged: (v) => saveSetting(location: v),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                      "Notifikasi Terbaru", "Alert dari backend"),
                  const SizedBox(height: 10),
                  NotificationsCard(
                    notifEnabled: profileState.notif,
                    notifications: notifList,
                    onRead: markNotificationRead,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader("Tentang", "Informasi aplikasi"),
                  const SizedBox(height: 10),
                  const AboutCard(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: logout,
                      icon:
                          const Icon(Icons.logout_rounded, color: Colors.white),
                      label: const Text(
                        "Keluar Akun",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
