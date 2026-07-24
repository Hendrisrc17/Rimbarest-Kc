// File: lib/screens/particulate/sensor_monitoring_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/particulate_service.dart';
import '../../theme/app_theme.dart';

class SensorMonitoringScreen extends StatefulWidget {
  const SensorMonitoringScreen({super.key});

  @override
  State<SensorMonitoringScreen> createState() => _SensorMonitoringScreenState();
}

class _SensorMonitoringScreenState extends State<SensorMonitoringScreen> {
  List<dynamic> allReadings = [];
  bool loading = true;
  String? errorMessage;
  Timer? _liveStreamTimer;

  @override
  void initState() {
    super.initState();
    fetchIotHistory();

    _liveStreamTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchIotHistory(isSilent: true);
    });
  }

  @override
  void dispose() {
    _liveStreamTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchIotHistory({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final List<dynamic> historyData = await ParticulateService.getHistory();

      if (!mounted) return;

      setState(() {
        allReadings = historyData;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = e.toString().replaceAll("Exception:", "").trim();
      });
    }
  }

  String _formatTime(dynamic recordedAt) {
    if (recordedAt == null) return "--:--";
    try {
      final dateTime = DateTime.parse(recordedAt.toString()).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final second = dateTime.second.toString().padLeft(2, '0');
      return "$hour:$minute:$second";
    } catch (_) {
      return "--:--";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Data Stream Perangkat IoT",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "Data Monitoring Sensor Partikulat & Lingkungan",
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14, left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              // 🔥 FIX 1: Penggunaan withValues
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.sync, size: 14, color: AppTheme.success),
                SizedBox(width: 4),
                Text("LIVE",
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchIotHistory(),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: Center(
                          child: Text("Error: $errorMessage",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.danger)),
                        ),
                      ),
                    ],
                  )
                : allReadings.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: const Center(
                              child: Text(
                                  "Belum ada logs data sensor terdaftar.",
                                  style: TextStyle(color: Colors.black54)),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: _buildSafeScrollableTable(),
                      ),
      ),
    );
  }

  Widget _buildSafeScrollableTable() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allReadings.length + 1,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                color: Colors.grey[200],
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text("ID/NODE",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11))),
                    Expanded(
                        flex: 1,
                        child: Text("TIME",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 1,
                        child: Text("PM 1.0",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 1,
                        child: Text("PM 2.5",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 1,
                        child: Text("PM 10",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 1,
                        child: Text("TEMP",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11),
                            textAlign: TextAlign.center)),
                    Expanded(
                        flex: 1,
                        child: Text("HUMID",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11),
                            textAlign: TextAlign.center)),
                  ],
                ),
              );
            }

            final r = allReadings[index - 1];
            final isLatest = (index - 1) == 0;

            final String nodeLabel = r["nodeCode"] ??
                r["node_name"] ??
                r["node"]?["name"] ??
                r["node"]?["nodeCode"] ??
                (r["nodeId"] != null
                    ? r["nodeId"]
                        .toString()
                        .substring(0, mathMin(5, r["nodeId"].toString().length))
                    : "IoT");

            return Container(
              // 🔥 FIX 2: Penggunaan withValues
              color: isLatest
                  ? AppTheme.success.withValues(alpha: 0.12)
                  : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        if (isLatest)
                          const Icon(Icons.flash_on,
                              size: 10, color: AppTheme.success),
                        if (isLatest) const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            nodeLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: isLatest
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isLatest
                                    ? AppTheme.success
                                    : Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      flex: 1,
                      child: Text(
                          _formatTime(r['recordedAt'] ?? r['recorded_at']),
                          style: TextStyle(
                              fontSize: 10,
                              color: isLatest
                                  ? AppTheme.success
                                  : Colors.grey[700],
                              fontWeight: isLatest
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 1,
                      child: Text("${r['pm1'] ?? '0.0'}",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: isLatest
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 1,
                      child: Text("${r['pm25'] ?? '0.0'}",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: isLatest
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  isLatest ? AppTheme.primary : Colors.black),
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 1,
                      child: Text("${r['pm10'] ?? '0.0'}",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: isLatest
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 1,
                      child: Text(
                          "${r['suhu'] ?? r['temperature'] ?? r['temp'] ?? '0'}",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: isLatest
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                          textAlign: TextAlign.center)),
                  Expanded(
                      flex: 1,
                      child: Text(
                          "${r['kelembapan'] ?? r['humidity'] ?? r['humid'] ?? '0'}%",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: isLatest
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                          textAlign: TextAlign.center)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  int mathMin(int a, int b) => a < b ? a : b;
}
