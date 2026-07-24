// File: lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class AuthService {
  static const String _tokenKey = "token";
  static const String _userKey = "user";

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  static dynamic _handle(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data["message"] ?? data["error"] ?? "Request gagal");
  }

  // ==========================================
  // FITUR: AUTHENTICATION & SESSION
  // ==========================================

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/mobile/login-register/register"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: jsonEncode({
        "firstName": firstName,
        "username": username,
        "email": email,
        "phone": phone,
        "password": password,
      }),
    );

    final data = _handle(response);
    if (data["data"]?["token"] != null) {
      await saveSession(data["data"]["token"], data["data"]["user"]);
    }
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/mobile/login-register/login"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: jsonEncode({
        "username": email,
        "email": email,
        "usernameOrEmail": email,
        "password": password
      }),
    );

    final data = _handle(response);
    if (data["data"]?["token"] != null) {
      await saveSession(data["data"]["token"], data["data"]["user"]);
    }
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/mobile/login-register/me"),
      headers: await _headers(),
    );

    final data = _handle(response);
    if (data["data"] != null) {
      final token = await getToken();
      if (token != null) {
        await saveSession(token, data["data"]);
      }
    }
    return Map<String, dynamic>.from(data);
  }

  static Future<void> saveSession(String token, dynamic user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<void> logout() async {
    await clearSession();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString == null) return null;
    return Map<String, dynamic>.from(jsonDecode(userString));
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ==========================================
  // FITUR: MONITORING & DASHBOARD DATA
  // ==========================================

  static Future<Map<String, dynamic>> dashboardSummary() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/mobile/dashboard"),
      headers: await _headers(),
    );

    final rawData = _handle(response);
    final dataContent = rawData["data"] ?? rawData;
    final current = dataContent["currentReadings"] ?? {};

    return Map<String, dynamic>.from({
      "success": rawData["success"] ?? true,
      "message": rawData["message"] ?? "",
      "data": dataContent,
      "summary": dataContent["summary"] ?? {},
      "latestReadings": dataContent["latestReadings"] ?? [],
      "latestIncidents": dataContent["latestIncidents"] ?? [],
      "aiInsight": dataContent["aiInsight"],
      "currentReadings": current,
      ...current,
    });
  }

  // MENGAMBIL ALERT NOTIFIKASI GABUNGAN
  static Future<List<dynamic>> fetchAlerts() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/mobile/alert"),
        headers: await _headers(),
      );

      final rawData = _handle(response);
      final dataContent = rawData["data"] ?? rawData;
      return dataContent["alerts"] ?? [];
    } catch (e) {
      return [];
    }
  }

  // 🔥 FITUR BARU: TANDAI SEMUA ALERT DIBACA (SOLUSI UNDEFINED_METHOD)
  static Future<bool> markAllAlertsAsRead() async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/mobile/alert/read-all"),
        headers: await _headers(),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getLiveAudioMonitoring() async {
    final response = await http.get(
        Uri.parse(
            "${ApiConfig.baseUrl}/mobile/live-monitoring-frekuensi-audio"),
        headers: await _headers());
    return Map<String, dynamic>.from(_handle(response));
  }

  static Future<Map<String, dynamic>> getLiveParticulateMonitoring() async {
    final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/mobile/live-monitoring-partikulat"),
        headers: await _headers());
    return Map<String, dynamic>.from(_handle(response));
  }

  static Future<Map<String, dynamic>> getNodes() async {
    final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/mobile/node"),
        headers: await _headers());
    return Map<String, dynamic>.from(_handle(response));
  }

  static Future<Map<String, dynamic>> getNodeDetail(String nodeCode) async {
    final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/mobile/node/$nodeCode"),
        headers: await _headers());
    return Map<String, dynamic>.from(_handle(response));
  }

  static Future<Map<String, dynamic>> getAiAudioPrediction() async {
    final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/mobile/prediksi-ai-audio"),
        headers: await _headers());
    return Map<String, dynamic>.from(_handle(response));
  }

  static Future<Map<String, dynamic>> notifications() async {
    final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/mobile/notifikasi"),
        headers: await _headers());
    return Map<String, dynamic>.from(_handle(response));
  }

  static Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/mobile/notifikasi"),
      headers: await _headers(),
      body: jsonEncode({"id": id, "status": "dibaca"}),
    );
    return Map<String, dynamic>.from(_handle(response));
  }

  // ==========================================
  // FITUR: UPDATE UTILITY
  // ==========================================

  static Future<Map<String, dynamic>> syncFcmToken({
    required String fcmToken,
    required String platform,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/mobile/profile/token"),
      headers: await _headers(),
      body: jsonEncode({
        "fcmToken": fcmToken,
        "platform": platform,
      }),
    );
    return Map<String, dynamic>.from(_handle(response));
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    bool? locationEnabled,
    bool? nightMode,
    bool? notificationEnabled,
    String? syncInterval,
  }) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/mobile/login-register/me"),
      headers: await _headers(),
      body: jsonEncode({
        "firstName": firstName,
        "lastName": lastName,
        "phone": phone,
        "address": address,
        "locationEnabled": locationEnabled,
        "nightMode": nightMode,
        "notificationEnabled": notificationEnabled,
        "syncInterval": syncInterval,
      }),
    );

    final data = _handle(response);

    if (data["data"] != null) {
      final token = await getToken();
      if (token != null) {
        await saveSession(token, data["data"]);
      }
    }

    return Map<String, dynamic>.from(data);
  }
}
