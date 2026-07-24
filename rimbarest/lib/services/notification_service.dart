// File: lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// 🚀 FUNGSI GLOBAL TOP-LEVEL UNTUK BACKGROUND / TERMINATED STATE
/// Wajib berada di luar class agar berjalan di thread Android mandiri (saat user buka aplikasi lain / HP mati)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
      "📩 Menerima pesan darurat di Background/Terminated: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 🚀 1. INISIALISASI UTAMA UNTUK HEADS-UP / BANNER MELAYANG
  static Future<void> inisialisasi() async {
    // Daftarkan Android High Importance Channel secara live ke OS
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'rimbarest_alerts', // 🚨 WAJIB SAMA dengan channelId di Backend Next.js!
      'RimbaRest High Alert Channel',
      description:
          'Channel untuk notifikasi darurat pembalakan liar dan kebakaran hutan.',
      importance: Importance
          .max, // Mengizinkan notifikasi melayang di atas semua aplikasi lain!
      playSound: true,
      enableVibration: true,
    );

    // Ambil implementasi spesifik Android untuk mendaftarkan channel
    final androidPlugin =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }

    // Atur setelan ikon notifikasi di bar atas HP
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // 🔧 FIX ABSOLUT: Menggunakan named parameter 'settings:' agar linter tidak eror lagi
    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
            "🎯 Spanduk notifikasi di-klik oleh user: ${response.payload}");
      },
    );

    // 🚀 2. BACKGROUND REGISTER (Supaya jebol pas buka YouTube/Aplikasi lain)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🚀 3. FOREGROUND LISTENERS (Saat aplikasi sedang dibuka)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;

      String? title = notification?.title ?? message.data['title'];
      String? body =
          notification?.body ?? message.data['message'] ?? message.data['body'];

      if (title != null || body != null) {
        _localNotificationsPlugin.show(
          id: (title.hashCode ^ body.hashCode) & 0x7FFFFFFF,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance:
                  Importance.max, // Memaksa spanduk muncul melayang (Heads-up)
              priority: Priority
                  .high, // Prioritas tinggi agar langsung didahulukan oleh Android
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableLights: true,
              styleInformation: BigTextStyleInformation(
                  body ?? ''), // Supaya teks panjang tidak kepotong
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // Ambil token untuk disimpan/debugging di terminal
    String? token = await _firebaseMessaging.getToken();
    debugPrint("📱 FCM Device Token Anda: $token");
  }
}
