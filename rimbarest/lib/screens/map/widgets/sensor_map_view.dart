// File: lib/screens/map/widgets/sensor_map_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/app_theme.dart';
import '../data/map_node_data.dart';

class SensorMapView extends StatefulWidget {
  final List<MapNodeData> nodes;
  final dynamic selectedNode;
  final AnimationController pingCtrl;
  final ValueChanged<dynamic>
      onNodeTap; // Menggunakan dynamic agar aman dari String/int

  const SensorMapView({
    super.key,
    required this.nodes,
    required this.selectedNode,
    required this.pingCtrl,
    required this.onNodeTap,
  });

  @override
  State<SensorMapView> createState() => _SensorMapViewState();
}

class _SensorMapViewState extends State<SensorMapView> {
  StreamSubscription<Position>? _positionStreamSubscription;
  final MapController _mapController = MapController();

  LatLng? _userLocation; // Lokasi HP Pengguna
  bool _hasMovedCamera = false;

  @override
  void initState() {
    super.initState();
    _initLiveLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLiveLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Stream GPS HP real-time HANYA untuk menandai posisi HP pengguna (Dot Biru)
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);

          // Pusatkan peta ke Node Sensor aktif pertama jika kamera belum pernah digeser
          if (!_hasMovedCamera) {
            if (widget.nodes.isNotEmpty &&
                widget.nodes[0].latitude != 0.0 &&
                widget.nodes[0].longitude != 0.0) {
              _mapController.move(
                LatLng(widget.nodes[0].latitude, widget.nodes[0].longitude),
                15.0,
              );
            } else if (_userLocation != null) {
              _mapController.move(_userLocation!, 15.0);
            }
            _hasMovedCamera = true;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan titik tengah awal peta dari Node Pertama atau Posisi User (dengan fallback koordinat default)
    final double defaultLat =
        (widget.nodes.isNotEmpty && widget.nodes[0].latitude != 0.0)
            ? widget.nodes[0].latitude
            : -2.129486;
    final double defaultLng =
        (widget.nodes.isNotEmpty && widget.nodes[0].longitude != 0.0)
            ? widget.nodes[0].longitude
            : 106.113042;

    final LatLng initialCenter =
        _userLocation ?? LatLng(defaultLat, defaultLng);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderMedium),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 15.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.rimbarest.app',
            ),
            MarkerLayer(
              markers: [
                // 1. PIN NODE SENSOR (Ditampilkan selalu, fallback ke koordinat default jika 0.0)
                ...widget.nodes.map((node) {
                  final bool isSelected =
                      widget.selectedNode.toString() == node.id.toString();

                  // Jika latitude/longitude masih 0.0, arahkan sementara ke titik default agar pin tetap muncul
                  final double pinLat =
                      (node.latitude == 0.0) ? -2.143011 : node.latitude;
                  final double pinLng =
                      (node.longitude == 0.0) ? 106.094274 : node.longitude;

                  return Marker(
                    point: LatLng(pinLat, pinLng),
                    width: 65,
                    height: 65,
                    child: GestureDetector(
                      onTap: () => widget.onNodeTap(node.id),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Radar Ping Animation
                          AnimatedBuilder(
                            animation: widget.pingCtrl,
                            builder: (context, child) {
                              return Container(
                                width: 15 + (widget.pingCtrl.value * 35),
                                height: 15 + (widget.pingCtrl.value * 35),
                                decoration: BoxDecoration(
                                  color: node.color.withValues(
                                      alpha: 1.0 - widget.pingCtrl.value),
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          ),
                          // Icon Pin Node
                          Icon(
                            node.icon,
                            color: isSelected ? Colors.amber : node.color,
                            size: isSelected ? 42 : 34,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // 2. INDICATOR LOKASI HP PENGGUNA (TITIK BIRU SAYA)
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
