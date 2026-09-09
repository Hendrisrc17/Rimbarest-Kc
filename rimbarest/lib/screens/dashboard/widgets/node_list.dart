import 'package:flutter/material.dart';

import '../../../widgets/app_widgets.dart';

class NodeList extends StatelessWidget {
  final List<dynamic> nodes; // Penerima data array dari API

  const NodeList({
    super.key,
    required this.nodes,
  });

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            "Tidak ada node pemantauan yang aktif.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: nodes.map((n) {
        // 🌟 STRATEGI DUA JALUR (ADAPTIF):
        // Jalur A: Jika item adalah objek 'SensorReading' langsung (mengandung key 'pm25')
        // Jalur B: Jika item adalah objek 'DeviceNode' biasa (mengandung nested array/object)
        final bool isReadingDirect = n['pm25'] != null;

        // 1. Ekstraksi Informasi Node secara dinamis
        final nodeObj = isReadingDirect ? n['node'] : n;
        final String nodeName = nodeObj?['name']?.toString() ??
            nodeObj?['nodeCode']?.toString() ??
            'Node Sensor';
        final String nodeStatus = nodeObj?['status']?.toString() ?? 'ONLINE';

        // 2. Ekstraksi Metrik PM2.5 secara dinamis
        String pmValue = '0';
        if (isReadingDirect) {
          pmValue = n['pm25']?.toString() ?? '0';
        } else if (n['readings'] is List &&
            (n['readings'] as List).isNotEmpty) {
          pmValue = n['readings'][0]['pm25']?.toString() ?? '0';
        }

        // 3. Ekstraksi Desibel (noiseLevel) / Battery Level secara aman
        // Mengutamakan noiseLevel desibel (dB) dari MAX9814 sesuai fungsionalitas RimbaRest
        String dbValue = '0';
        if (isReadingDirect) {
          dbValue = n['noiseLevel']?.toString() ??
              n['batteryLevel']?.toString() ??
              '0';
        } else if (n['readings'] is List &&
            (n['readings'] as List).isNotEmpty) {
          final topReading = n['readings'][0];
          dbValue = topReading['noiseLevel']?.toString() ??
              topReading['batteryLevel']?.toString() ??
              '0';
        }

        // 4. Hilangkan digit desimal berlebih jika bertipe double agar tampilan UI rapi
        String cleanString(String val) {
          final parsed = num.tryParse(val);
          if (parsed is double) return parsed.toStringAsFixed(1);
          return parsed?.toString() ?? '0';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: NodeRow(
            name: nodeName,
            status: nodeStatus,
            pm: cleanString(pmValue),
            db: cleanString(dbValue),
          ),
        );
      }).toList(),
    );
  }
}
