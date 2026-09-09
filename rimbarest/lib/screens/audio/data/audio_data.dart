// File: lib/screens/audio/data/audio_data.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

// Helper dinamis untuk menerjemahkan label deteksi mentah dari FastAPI & Next.js ke visual UI HP
class AudioVisualHelper {
  static Map<String, dynamic> getStyle(String label) {
    final l = label.toLowerCase();

    // 🚨 1. KELOMPOK ANCAMAN BINER / UMUM (Model AI Baru)
    if (l.contains('ancaman') ||
        l.contains('positif') ||
        l.contains('threat')) {
      return {
        'icon': '🚨',
        'label': 'Ancaman Terdeteksi',
        'color': AppTheme.danger,
        'bg': AppTheme.bgDanger,
        'border': AppTheme.bdrDanger,
        'isAnomaly': true,
      };
    }

    // 🪓 2. KELOMPOK ANCAMAN SPESIFIK (Model AI Legacy / Multi-class)
    else if (l.contains('chainsaw') || l.contains('saw')) {
      return {
        'icon': '🪚',
        'label': 'Gergaji Mesin (Chainsaw)',
        'color': AppTheme.danger,
        'bg': AppTheme.bgDanger,
        'border': AppTheme.bdrDanger,
        'isAnomaly': true,
      };
    } else if (l.contains('gunshot')) {
      return {
        'icon': '💥',
        'label': 'Tembakan Senjata',
        'color': AppTheme.danger,
        'bg': AppTheme.bgDanger,
        'border': AppTheme.bdrDanger,
        'isAnomaly': true,
      };
    } else if (l.contains('axe')) {
      return {
        'icon': '🪓',
        'label': 'Penebangan Kapak',
        'color': AppTheme.danger,
        'bg': AppTheme.bgDanger,
        'border': AppTheme.bdrDanger,
        'isAnomaly': true,
      };
    } else if (l.contains('engine') ||
        l.contains('gen') ||
        l.contains('woodchp')) {
      return {
        'icon': '⚙️',
        'label': 'Mesin / Generator',
        'color': AppTheme.warning,
        'bg': AppTheme.bgWarning,
        'border': AppTheme.bdrWarning,
        'isAnomaly': true,
      };
    } else if (l.contains('treefall')) {
      return {
        'icon': '🌳',
        'label': 'Pohon Tumbang',
        'color': AppTheme.warning,
        'bg': AppTheme.bgWarning,
        'border': AppTheme.bdrWarning,
        'isAnomaly': true,
      };
    }

    // 🐦 3. KELOMPOK SUARA ALAMI HUTAN (Normal Ambient)
    else if (l.contains('bird') ||
        l.contains('fauna') ||
        l.contains('squirrel') ||
        l.contains('wolf') ||
        l.contains('lion')) {
      return {
        'icon': '🐦',
        'label': label,
        'color': AppTheme.success,
        'bg': AppTheme.bgSuccess,
        'border': AppTheme.bdrSuccess,
        'isAnomaly': false,
      };
    } else if (l.contains('rain') ||
        l.contains('wind') ||
        l.contains('thunder') ||
        l.contains('waterdp')) {
      return {
        'icon': '🌀',
        'label': 'Suara Alam ($label)',
        'color': Colors.blue,
        'bg': Colors.blue.withValues(alpha: 0.05),
        'border': Colors.blue.withValues(alpha: 0.2),
        'isAnomaly': false,
      };
    }

    // 🍃 4. FALLBACK AMAN
    else {
      return {
        'icon': '🍃',
        'label':
            label.isNotEmpty && label != 'Silence' ? label : 'Normal Ambient',
        'color': AppTheme.secondary,
        'bg': AppTheme.bgSecondary,
        'border': AppTheme.borderMedium,
        'isAnomaly': false,
      };
    }
  }
}

const List<String> audioCategories = [
  'Semua',
  'Anomali',
  'Normal',
];
