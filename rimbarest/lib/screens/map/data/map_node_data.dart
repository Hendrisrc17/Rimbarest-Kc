// File: lib/screens/map/data/map_node_data.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

enum MapNodeStatus {
  good,
  warning,
  critical,
  offline,
}

class MapNodeData {
  final dynamic id;
  final String nodeCode;
  final String name;

  double latitude;
  double longitude;

  MapNodeStatus status;
  double pm;
  double db;

  String customAiLabel;

  MapNodeData({
    required this.id,
    required this.nodeCode,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.pm,
    required this.db,
    this.customAiLabel = 'MEMUAT DATA SENSOR...',
  });

  Color get color {
    switch (status) {
      case MapNodeStatus.critical:
        return Colors.red.shade900;
      case MapNodeStatus.warning:
        return AppTheme.danger;
      case MapNodeStatus.offline:
        return Colors.grey;
      case MapNodeStatus.good:
        return AppTheme.success;
    }
  }

  IconData get icon {
    switch (status) {
      case MapNodeStatus.critical:
        return Icons.local_fire_department_rounded;
      case MapNodeStatus.warning:
        return Icons.warning_rounded;
      case MapNodeStatus.offline:
        return Icons.location_off_rounded;
      case MapNodeStatus.good:
        return Icons.location_on_rounded;
    }
  }

  String get statusLabel => customAiLabel;
  bool get isOnline => status != MapNodeStatus.offline;

  void updateFromApi(Map<String, dynamic> json) {
    try {
      Map<String, dynamic> sourceData = json;
      if (json['latestReading'] != null && json['latestReading'] is Map) {
        sourceData = Map<String, dynamic>.from(json['latestReading']);
      } else if (json['sensorReadings'] != null &&
          (json['sensorReadings'] as List).isNotEmpty) {
        sourceData = Map<String, dynamic>.from(json['sensorReadings'].first);
      }

      // 🔥 AMBIL LATITUDE & LONGITUDE SENSOR GPS RIIL
      final rawLat = sourceData['latitude'] ?? json['latitude'];
      final rawLng = sourceData['longitude'] ?? json['longitude'];

      if (rawLat != null) {
        final parsedLat = double.tryParse(rawLat.toString());
        if (parsedLat != null && parsedLat != 0.0) {
          latitude = parsedLat;
        }
      }
      if (rawLng != null) {
        final parsedLng = double.tryParse(rawLng.toString());
        if (parsedLng != null && parsedLng != 0.0) {
          longitude = parsedLng;
        }
      }

      pm = double.tryParse(sourceData['pm25']?.toString() ?? '0.0') ?? 0.0;
      db = double.tryParse(sourceData['noiseLevel']?.toString() ??
              sourceData['db']?.toString() ??
              '0.0') ??
          0.0;

      String statusAiRaw = sourceData['statusTerpadu']?.toString() ??
          json['statusTerpadu']?.toString() ??
          json['status']?.toString() ??
          sourceData['status']?.toString() ??
          '✅ NORMAL BERSIH';

      customAiLabel = statusAiRaw.toUpperCase();

      String statusLower = statusAiRaw.toLowerCase();
      if (statusLower.contains('kebakaran') ||
          statusLower.contains('besar') ||
          statusLower.contains('ancaman') ||
          statusLower.contains('kritis')) {
        status = MapNodeStatus.critical;
      } else if (statusLower.contains('waspada') ||
          statusLower.contains('warning') ||
          statusLower.contains('asap') ||
          statusLower.contains('polusi')) {
        status = MapNodeStatus.warning;
      } else if (statusLower.contains('offline') ||
          json['status'] == 'OFFLINE') {
        status = MapNodeStatus.offline;
      } else {
        status = MapNodeStatus.good;
      }

      debugPrint(
          '📍 MAP UPDATE RIIL -> Node: $nodeCode, Lat: $latitude, Lng: $longitude, PM: $pm, AI: $customAiLabel');
    } catch (e) {
      debugPrint('🚨 Gagal urai JSON di map_node_data: $e');
    }
  }
}

// 🚀 INITIAL ITEM UNTUK DITEMPATKAN DI PETA AWAL (AKAN DI-UPDATE OTOMATIS OLEH SENSOR GPS)
List<MapNodeData> globalMapNodes = [
  MapNodeData(
    id: 'NODE-001',
    nodeCode: 'NODE-001',
    name: 'Node Pemantau 01',
    latitude: 0.0, // Akan diperbarui langsung oleh GPS sensor
    longitude: 0.0, // Akan diperbarui langsung oleh GPS sensor
    status: MapNodeStatus.good,
    pm: 0.0,
    db: 0.0,
    customAiLabel: 'MENUNGGU SENSOR GPS...',
  ),
];
