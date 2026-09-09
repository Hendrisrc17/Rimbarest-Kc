// File: lib/screens/audio/audio_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../auth/auth_service.dart';
import 'data/audio_data.dart'; // Digunakan kembali untuk AudioVisualHelper
import 'widgets/audio_app_bar.dart';
import 'widgets/audio_category_filter.dart';
import 'widgets/audio_event_list.dart';
import 'widgets/audio_spectrum.dart';
import 'widgets/audio_wave_box.dart';
import 'widgets/node_tabs.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen>
    with TickerProviderStateMixin {
  late final AnimationController waveCtrl;
  late final AnimationController pulseCtrl;

  Timer? _pollingTimer;
  bool _isLoading = true;
  List<dynamic> _nodesList = [];
  List<dynamic> _allIncidents = [];
  int selectedNodeIndex = 0;
  String selectedCat = 'Semua';
  double currentLiveDb = 50.0;

  @override
  void initState() {
    super.initState();

    waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();

    pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fetchLiveAudioData();

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _fetchLiveAudioData();
      }
    });
  }

  Future<void> _fetchLiveAudioData() async {
    try {
      // Menggunakan dashboardSummary sebagai jembatan pembaca jika getCustomEndpoint tidak ada
      final data = await AuthService.dashboardSummary();

      if (mounted) {
        setState(() {
          // Fallback parsing aman untuk menghindari error runtime
          _nodesList = data['latestReadings'] ?? [];
          _allIncidents = data['latestIncidents'] ?? [];
          _isLoading = false;

          if (_nodesList.isNotEmpty && selectedNodeIndex < _nodesList.length) {
            final activeNodeReading = _nodesList[selectedNodeIndex];
            currentLiveDb = double.tryParse(
                    activeNodeReading['noiseLevel']?.toString() ?? '50.0') ??
                50.0;
          }
        });
      }
    } catch (e) {
      debugPrint("⚠️ Live monitoring sync warning: $e");
    }
  }

  List<dynamic> _getFilteredIncidents() {
    if (selectedCat == 'Semua') return _allIncidents;

    return _allIncidents.where((incident) {
      final label = incident['label']?.toString() ?? 'Silence';
      final style = AudioVisualHelper.getStyle(label);
      final bool isAnomalyItem = style['isAnomaly'] ?? false;

      if (selectedCat == 'Anomali') return isAnomalyItem;
      if (selectedCat == 'Normal') return !isAnomalyItem;
      return false;
    }).toList();
  }

  @override
  void dispose() {
    waveCtrl.dispose();
    pulseCtrl.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _getFilteredIncidents();

    final List<String> dynamicNodeNames = _nodesList.isNotEmpty
        ? _nodesList.map((n) {
            final nodeInfo = n['node'] ?? {};
            return nodeInfo['name']?.toString() ?? 'Station';
          }).toList()
        : ['A1 Hutan Lindung'];

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: RefreshIndicator(
        onRefresh: _fetchLiveAudioData,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const AudioAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AudioWaveBox(
                    waveCtrl: waveCtrl,
                    pulseCtrl: pulseCtrl,
                    currentDb: currentLiveDb,
                  ),
                  const SizedBox(height: 14),

                  _isLoading
                      ? const Center(child: LinearProgressIndicator())
                      : NodeTabs(
                          selectedIndex: selectedNodeIndex,
                          nodeNames: dynamicNodeNames,
                          onChanged: (i) {
                            setState(() {
                              selectedNodeIndex = i;
                            });
                          },
                        ),
                  const SizedBox(height: 8),
                  const SectionHeader(
                    title: 'Klasifikasi Suara AI',
                    subtitle: 'Deteksi ancaman kritis real-time',
                  ),
                  const SizedBox(height: 4),
                  AudioCategoryFilter(
                    selected: selectedCat,
                    onChanged: (v) => setState(() => selectedCat = v),
                  ),
                  const SizedBox(height: 2),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : AudioEventList(
                          events:
                              filteredEvents), // Sesuai dengan parameter 'events' bawaan widget Anda

                  const SizedBox(height: 14),
                  AudioSpectrum(
                    waveCtrl: waveCtrl,
                    currentDb: currentLiveDb,
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
