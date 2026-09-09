import 'package:flutter/material.dart';

// 🌟 DIUBAH MENJADI DEDICATED MODEL DATA UTK MAPPING
class DashboardStatData {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final String status;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final String trend;
  final bool trendUp;

  const DashboardStatData({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.status,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.trend,
    required this.trendUp,
  });
}

class NodeData {
  final String name;
  final String status;
  final String pm;
  final String db;

  const NodeData({
    required this.name,
    required this.status,
    required this.pm,
    required this.db,
  });
}
