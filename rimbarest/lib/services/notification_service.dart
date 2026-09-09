// File: lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// 🚀 FUNGSI GLOBAL TOP-LEVEL UNTUK BACKGROUND / TERMINATED STATE
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
    // Request permission (Wajib untuk Android 13+ & iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint("⚠️ Pengguna menolak izin notifikasi.");
    } else {
      debugPrint(
          "✅ Izin notifikasi diberikan: ${settings.authorizationStatus}");
    }

    // Daftarkan Android High Importance Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'rimbarest_alerts',
      'RimbaRest High Alert Channel',
      description:
          'Channel untuk notifikasi darurat pembalakan liar dan kebakaran hutan.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // 🔧 FIX: Menggunakan named parameter `settings:`
    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
            "🎯 Spanduk notifikasi di-klik oleh user: ${response.payload}");
      },
    );

    // Background Listener
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground Listener (Saat aplikasi sedang dibuka)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;

      String? title = notification?.title ?? message.data['title'];
      String? body =
          notification?.body ?? message.data['message'] ?? message.data['body'];

      if (title != null || body != null) {
        // 🔧 FIX: Menggunakan named parameters (id, title, body, notificationDetails, payload)
        _localNotificationsPlugin.show(
          id: (title.hashCode ^ body.hashCode) & 0x7FFFFFFF,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableLights: true,
              styleInformation: BigTextStyleInformation(body ?? ''),
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint("📱 FCM Device Token Anda: $token");
    } catch (e) {
      debugPrint("🚨 Gagal mendapatkan FCM Token: $e");
    }
  }
}
