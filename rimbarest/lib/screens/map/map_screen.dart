// File: lib/screens/map/map_screen.dart
import 'dart:async';
import 'dart:convert'; // 🔥 FIX: Mengoreksi 'dart0:convert' menjadi 'dart:convert'
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

    // Lakukan polling hit API setiap 3 detik agar PM2.5 & Status terus update secara live
    _fetchTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchNodeDataFromServer();
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
      // ⚠️ GANTI IP INI dengan IP Laptop server Next.js kamu yang aktif sekarang!
      final url = Uri.parse('http://10.244.79.151:3000/api/nodes');

      final response = await http.get(url).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse.isNotEmpty && mounted) {
          setState(() {
            for (var nodeData in globalMapNodes) {
              // Cocokkan data berdasarkan nodeCode ('NODE-001')
              final match = jsonResponse.firstWhere(
                (element) => element['nodeCode'] == nodeData.nodeCode,
                orElse: () => null,
              );

              if (match != null) {
                nodeData.updateFromApi(match);
              }
            }
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
