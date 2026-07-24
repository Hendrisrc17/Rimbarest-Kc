import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

const particulateTypes = [
  'PM1',
  'PM2.5',
  'PM10',
  'TempT',
  'Humid',
];

class AqiCategoryData {
  final String label;
  final String range;
  final Color color;
  final Color bg;
  final Color border;

  const AqiCategoryData({
    required this.label,
    required this.range,
    required this.color,
    required this.bg,
    required this.border,
  });
}

const aqiCategories = [
  AqiCategoryData(
    label: 'Baik',
    range: '0-50',
    color: AppTheme.success,
    bg: AppTheme.bgSuccess,
    border: AppTheme.bdrSuccess,
  ),
  AqiCategoryData(
    label: 'Sedang',
    range: '51-100',
    color: AppTheme.warning,
    bg: AppTheme.bgWarning,
    border: AppTheme.bdrWarning,
  ),
  AqiCategoryData(
    label: 'Tidak Sehat',
    range: '101-200',
    color: Color(0xFFEA580C),
    bg: Color(0xFFFFF7ED),
    border: Color(0xFFFED7AA),
  ),
  AqiCategoryData(
    label: 'Berbahaya',
    range: '201+',
    color: AppTheme.danger,
    bg: AppTheme.bgDanger,
    border: AppTheme.bdrDanger,
  ),
];

class NodeParticulateData {
  final String name;
  final double value;

  const NodeParticulateData({
    required this.name,
    required this.value,
  });
}

const nodeParticulateData = [
  NodeParticulateData(name: 'A1 Hutan Lindung', value: 22.1),
  NodeParticulateData(name: 'A2 Hutan Lindung', value: 31.4),
  NodeParticulateData(name: 'B1 Hutan Lindung', value: 67.2),
  NodeParticulateData(name: 'B2 Hutan Lindung', value: 18.9),
  NodeParticulateData(name: 'C1 Hutan Lindung', value: 29.5),
];

const trendParticulateData = [28.0, 31.0, 24.0, 22.0, 35.0, 67.2, 45.0];
