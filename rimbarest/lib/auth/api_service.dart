// File: lib/auth/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  static Future<dynamic> get(String endpoint) async {
    final formattedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = Uri.parse("${ApiConfig.baseUrl}/mobile$formattedEndpoint");

    final response = await http.get(url, headers: await _headers());
    return _handleResponse(response);
  }

  static Future<dynamic> post(
      String endpoint, Map<String, dynamic> body) async {
    // 🌟 BEBAS ERROR: Menggunakan 'endpoint' untuk pengecekan kondisi awal awal
    final formattedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = Uri.parse("${ApiConfig.baseUrl}/mobile$formattedEndpoint");

    final response =
        await http.post(url, headers: await _headers(), body: jsonEncode(body));
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    // 🌟 BEBAS ERROR: Menggunakan 'endpoint' untuk pengecekan kondisi awal awal
    final formattedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = Uri.parse("${ApiConfig.baseUrl}/mobile$formattedEndpoint");

    final response =
        await http.put(url, headers: await _headers(), body: jsonEncode(body));
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Otomatis mengembalikan isi field "data" dari struktur mobileOk Next.js
        return data["data"] ?? data;
      }

      throw Exception(data["message"] ??
          "Terjadi kesalahan server (${response.statusCode})");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Gagal memproses data dari server.");
    }
  }
}
