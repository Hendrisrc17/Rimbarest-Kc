// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  // 1. Pastikan binding mesin Flutter terinisialisasi sempurna di memori awal
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Kunci orientasi layar hanya tegak (Portrait) agar tata letak UI saat demo konstan
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    // 3. Inisialisasi Firebase menggunakan konfigurasi otomatis
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("🔥 Firebase Services berhasil diinisialisasi.");

    // 4. Jalankan infrastruktur penangkap notifikasi melayang
    await NotificationService.inisialisasi();
    debugPrint("🚨 Channel Notifikasi Melayang Berhasil Terpasang.");
  } catch (e) {
    debugPrint("🚨 Gagal menginisialisasi Firebase/Notifikasi: $e");
  }

  // 5. Mengatur skema warna transparan pada system UI overlay bawaan OS
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 6. Jalankan aplikasi utama RIMBAREST
  runApp(const RimbaRestApp());
}

/// 🚀 FUNGSI BYPASS OTOMATIS DAFTAR TOKEN KE BACKEND
Future<void> sinkronisasiTokenBypass() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      debugPrint("🚨 Gagal sinkronisasi: Token FCM bernilai null.");
      return;
    }

    // 🔧 IP Laptop/Hotspot untuk HP Fisik
    final url = Uri.parse('http://10.244.79.151:3000/api/mobile/user/token');

    debugPrint("📡 Mencoba sinkronisasi token secara otomatis ke backend...");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'isActive': true,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint(
          "✅ SUCCESS BYPASS: Perangkat terdaftar resmi di PostgreSQL backend!");
    } else {
      debugPrint(
          "⚠️ Backend merespons status: ${response.statusCode}. Cek kecocokan endpoint token kamu.");
    }
  } catch (e) {
    debugPrint("🚨 Gangguan koneksi saat mendaftarkan token ke backend: $e");
  }
}

/// 📡 FUNGSI PENGATURAN PERMISSION (IZIN APLIKASI) SECARA REAL-TIME
Future<void> cekIzinAplikasi() async {
  try {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.location,
      Permission.notification, // Wajib di Android 13+
    ].request();

    if (statuses[Permission.microphone]!.isDenied) {
      debugPrint("🚨 Warning: User menolak izin akses Mikrofon.");
    } else {
      debugPrint("✅ Izin Mikrofon berhasil didapatkan.");
    }

    if (statuses[Permission.location]!.isDenied) {
      debugPrint("🚨 Warning: User menolak izin akses Lokasi.");
    } else {
      debugPrint("✅ Izin Lokasi/GPS berhasil didapatkan.");
    }

    if (statuses[Permission.notification]!.isDenied) {
      debugPrint("🚨 Warning: User menolak izin akses Notifikasi Melayang.");
    } else {
      debugPrint("✅ Izin Push Notification berhasil didapatkan.");
    }
  } catch (e) {
    debugPrint("🚨 Gagal memproses inisialisasi izin aplikasi: $e");
  }
}

class RimbaRestApp extends StatelessWidget {
  const RimbaRestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RimbaRest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(
          AppTheme.lightTheme.textTheme,
        ),
      ),
      // 🚀 BUNGKUS DENGAN WIDGET PENGAMAN UNTUK MENJALANKAN DIALOG BEGITU UI RENDER SAKTI
      home: const InitializationGuard(child: SplashScreen()),
    );
  }
}

/// 🛡️ WIDGET PENGAMAN INI MEMASTIKAN DIALOG OPERATING SYSTEM DIJALANKAN
/// SETELAH MATERIAP & SPLASH SCREEN BERHASIL DIRENDER OLEH ENGINE FLUTTER
class InitializationGuard extends StatefulWidget {
  final Widget child;
  const InitializationGuard({super.key, required this.child});

  @override
  State<InitializationGuard> createState() => _InitializationGuardState();
}

class _InitializationGuardState extends State<InitializationGuard> {
  @override
  void initState() {
    super.initState();
    // 🧠 Pasca frame pertama selesai digambar di layar HP, jalankan asinkronus background tanpa memblokir UI thread
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await cekIzinAplikasi();
      await sinkronisasiTokenBypass();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
