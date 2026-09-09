// File: lib/screens/map/map_screen.dart
import 'dart:async';
import 'dart:convert'; // 👈 HAPUS 'dart0:convert', GUNAKAN INI SAJA
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_theme.dart';
import 'data/map_node_data.dart';
import 'widgets/map_header.dart';
import 'widgets/map_legend.dart';
import 'widgets/map_node_detail.dart';
import 'widgets/sensor_map_view.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController pingCtrl;

  dynamic selectedNode;
  Timer? _fetchTimer;

  @override
  void initState() {
    super.initState();

    pingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Jalankan pertama kali
    _fetchNodeDataFromServer();

    // Polling hit API setiap 3 detik
    _fetchTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _fetchNodeDataFromServer();
      }
    });
  }

  @override
  void dispose() {
    _fetchTimer?.cancel();
    pingCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchNodeDataFromServer() async {
    try {
      // 🔥 FIX: URL HTTPS Benar tanpa typo double protocol
      final url = Uri.parse('https://rimbarest.lab-ilkom.my.id/api/nodes');

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> jsonResponse = [];

        if (decoded is List) {
          jsonResponse = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          jsonResponse = decoded['data'];
        } else if (decoded is Map && decoded['nodes'] is List) {
          jsonResponse = decoded['nodes'];
        }

        if (jsonResponse.isNotEmpty && mounted) {
          setState(() {
            for (var nodeData in globalMapNodes) {
              final match = jsonResponse.firstWhere(
                (element) =>
                    (element['nodeCode'] ?? element['id'] ?? '') ==
                    nodeData.nodeCode,
                orElse: () => null,
              );

              if (match != null) {
                nodeData.updateFromApi(Map<String, dynamic>.from(match));
              }
            }

            // Default pilih node pertama jika belum ada yang terpilih
            selectedNode ??= globalMapNodes.first.id;
          });
        }
      }
    } catch (e) {
      debugPrint('🚨 API Error: $e');
    }
  }

  void toggleNode(dynamic id) {
    setState(() {
      selectedNode = (selectedNode.toString() == id.toString()) ? null : id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MapNodeData? selected = selectedNode == null || globalMapNodes.isEmpty
        ? null
        : globalMapNodes.firstWhere(
            (node) => node.id.toString() == selectedNode.toString(),
            orElse: () => globalMapNodes.first,
          );

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Column(
        children: [
          const MapHeader(),
          Expanded(
            child: SensorMapView(
              nodes: globalMapNodes,
              selectedNode: selectedNode,
              pingCtrl: pingCtrl,
              onNodeTap: toggleNode,
            ),
          ),
          if (selected != null) MapNodeDetail(node: selected),
          const MapLegend(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
