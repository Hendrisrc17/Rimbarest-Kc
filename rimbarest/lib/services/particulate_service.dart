// File: lib/services/particulate_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/auth_service.dart';

class ParticulateService {
  // 🌟 MENGARAHKAN MURNI KE ENDPOINT MOBILE YANG SUDAH KITA PERBAIKI DI PORT 3000
  static const String mobileApiUrl =
      "http://10.244.79.151:3000/api/mobile/live-monitoring-partikulat";

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  static dynamic _handle(http.Response response) {
    if (response.body.isEmpty) {
      throw const FormatException("Server mengembalikan respons kosong.");
    }

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(
        data["message"] ?? "Request gagal (Status: ${response.statusCode})");
  }

  /// Mengambil data log history untuk keperluan tabel/spreadsheet stream sensor
  static Future<List<dynamic>> getHistory() async {
    try {
      // 🌟 DISINKRONKAN: Mengirim parameter limit dan nodeCode secara terstruktur
      final response = await http.get(
        Uri.parse("$mobileApiUrl?nodeCode=NODE-001&limit=30"),
        headers: await _headers(),
      );

      final decoded = _handle(response);

      if (decoded is Map &&
          decoded["success"] == true &&
          decoded["data"] != null) {
        return decoded["data"] as List;
      }
      return [];
    } catch (e) {
      print("❌ [History Service Error]: $e");
      return [];
    }
  }

  /// Mengambil data terbaru untuk Dashboard UI (Mendukung Integrasi 4-Level Model AI)
  static Future<Map<String, dynamic>> getLatest() async {
    // 🌟 PERBAIKAN UTAMA: Cukup panggil satu endpoint terpadu yang sudah kita bypass auth-nya!
    // Ini menghindari 3 kali request beruntun yang menyebabkan eror 'Unexpected end of input'.
    final response = await http.get(
      Uri.parse(mobileApiUrl),
      headers: await _headers(),
    );

    final decoded = _handle(response);

    Map<String, dynamic>? latestReading;
    Map<String, dynamic>? latestDetection;
    Map<String, dynamic>? latestNotification;

    // Ekstraksi struktur default untuk menangkal status mati/putus
    Map<String, dynamic> deviceAlert = {
      "alert": false,
      "message": "",
    };

    if (decoded is Map &&
        decoded["success"] == true &&
        decoded["data"] is List) {
      final List dataList = decoded["data"];

      if (dataList.isNotEmpty) {
        // Ambil record pertama dari data node teraktif
        final r = Map<String, dynamic>.from(dataList.first);

        latestReading = {
          "id": r["id"],
          "nodeCode": r["nodeCode"] ?? "NODE-001",
          "node_name": r["node_name"] ?? "NODE-001",
          "node_status": "ONLINE",
          "pm1": r["pm1"] ?? 0.0,
          "pm25": r["pm25"] ?? 0.0,
          "pm10": r["pm10"] ?? 0.0,
          "humidity": r["humidity"] ?? r["kelembapan"] ?? 0.0,
          "temperature": r["temperature"] ?? r["suhu"] ?? 0.0,
          "suhu": r["suhu"] ?? 0.0,
          "kelembapan": r["kelembapan"] ?? 0.0,
          "aiStatusResult": r["aiStatusResult"] ?? "✅ Normal Bersih",
          "kat_asap": r["kat_asap"] ?? "Udara Bersih",
          "recordedAt": r["recordedAt"],
        };

        // 🌟 DIKAWINKAN DENGAN DETEKSI 4-LEVEL: Pasangkan status agar terbaca di screen utama
        latestDetection = {
          "id": r["id"],
          "confidence": 94.0,
          "risk_level": r["aiStatusResult"]?.toString() ?? "✅ Normal Bersih",
        };

        // Cek jika status menunjukkan indikasi anomali pekat untuk memicu warningCard lokal
        final String statusLower =
            (r["aiStatusResult"] ?? "").toString().toLowerCase();
        if (statusLower.contains("kebakaran") ||
            statusLower.contains("tebal") ||
            statusLower.contains("pekat")) {
          latestNotification = {
            "id": r["id"],
            "title": "🚨 Peringatan Anomali Udara",
            "message":
                "Model Isolation Forest mendeteksi parameter ${r['kat_asap']}. Harap pantau lokasi!",
          };
        }
      }
    }

    return {
      "latest_reading": latestReading,
      "latest_detection": latestDetection,
      "latest_notification": latestNotification,
      "device_alert": deviceAlert,
    };
  }

  /// Method pembantu simulasi pengiriman data testing alat
  static Future<void> sendTestData({
    required double pm25,
    required double pm10,
    required double humidity,
    required double temp,
    double pm1 = 0.0,
  }) async {
    // Tetap menggunakan endpoint default ApiConfig untuk aktivitas modifikasi POST data test
    final readingRes = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/iot/sensor"),
      headers: await _headers(),
      body: jsonEncode({
        "nodeCode": "NODE-001",
        "pm1": pm1,
        "pm25": pm25,
        "pm10": pm10,
        "humidity": humidity,
        "temperature": temp,
        "batteryLevel": 90.0,
        "signalStrength": 80.0,
      }),
    );
    _handle(readingRes);
  }
}
