// File: lib/screens/map/widgets/map_node_detail.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../data/map_node_data.dart';

class MapNodeDetail extends StatelessWidget {
  final MapNodeData node;

  const MapNodeDetail({
    super.key,
    required this.node,
  });

  @override
  Widget build(BuildContext context) {
    // 🤖 AMBIL STATUS MURNI DARI HASIL PREDIKSI AI SERVER
    String statusDariAI = node.statusLabel;

    // Default warna jika AI mendeteksi kondisi aman/normal
    Color warnaDinamis = Colors.green;

    // Ubah ke huruf kecil untuk pencocokan warna visual saja di Flutter
    String statusLower = statusDariAI.toLowerCase();

    // 🎨 Atur warna theme berdasarkan teks keputusan AI lu
    if (statusLower.contains('kebakaran') ||
        statusLower.contains('waspada') ||
        statusLower.contains('danger') ||
        statusLower.contains('high')) {
      warnaDinamis = Colors.red;
    } else if (statusLower.contains('offline') ||
        statusLower.contains('mati')) {
      warnaDinamis = Colors.grey;
    } else if (statusLower.contains('siaga') ||
        statusLower.contains('warning')) {
      warnaDinamis = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warnaDinamis.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: warnaDinamis.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: warnaDinamis.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              node.icon,
              color: warnaDinamis,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lat/Lon: ${node.latitude.toStringAsFixed(6)}, ${node.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Text(
                      'PM2.5: ',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '${node.pm.toStringAsFixed(1)} µg/m³',
                      style: TextStyle(
                        color: warnaDinamis,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${node.db.toStringAsFixed(1)} dB',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 🏷️ BADGE STATUS YANG MENAMPILKAN APAPUN KATA AI LU
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: warnaDinamis.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: warnaDinamis.withValues(alpha: 0.4)),
            ),
            child: Text(
              statusDariAI, // <-- Murni Teks Output dari Model AI Server Lu
              style: TextStyle(
                color: warnaDinamis,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
