// File: lib/services/particulate_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// 💡 FIX IMPORT: Menggunakan relative import untuk file di folder yang sama
import '../../auth/api_config.dart';
import '../../auth/auth_service.dart';

class ParticulateService {
  // 🚀 MENGGUNAKAN BASE URL TERPUSAT PRODUCTION
  static String get mobileApiUrl =>
      "${ApiConfig.baseUrl}/mobile/live-monitoring-partikulat";

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
      // 💡 FIX LINTER: Mengganti print() dengan debugPrint()
      debugPrint("❌ [History Service Error]: $e");
      return [];
    }
  }

  /// Mengambil data terbaru untuk Dashboard UI (Mendukung Integrasi 4-Level Model AI)
  static Future<Map<String, dynamic>> getLatest() async {
    final response = await http.get(
      Uri.parse(mobileApiUrl),
      headers: await _headers(),
    );

    final decoded = _handle(response);

    Map<String, dynamic>? latestReading;
    Map<String, dynamic>? latestDetection;
    Map<String, dynamic>? latestNotification;

    Map<String, dynamic> deviceAlert = {
      "alert": false,
      "message": "",
    };

    if (decoded is Map &&
        decoded["success"] == true &&
        decoded["data"] is List) {
      final List dataList = decoded["data"];

      if (dataList.isNotEmpty) {
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

        latestDetection = {
          "id": r["id"],
          "confidence": 94.0,
          "risk_level": r["aiStatusResult"]?.toString() ?? "✅ Normal Bersih",
        };

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
