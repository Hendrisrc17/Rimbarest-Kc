// File: lib/screens/audio/widgets/audio_event_list.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../data/audio_data.dart';
import '../../../theme/app_theme.dart';

// 🚀 KONFIGURASI TERPUSAT IP LAPTOP AI SERVER
const String kFallbackAiServerBaseUrl = "http://10.244.79.151:8000";

class AudioEventList extends StatefulWidget {
  final List<dynamic> events;

  const AudioEventList({
    super.key,
    required this.events,
  });

  @override
  State<AudioEventList> createState() => _AudioEventListState();
}

class _AudioEventListState extends State<AudioEventList> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingIndex;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.release);

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playingIndex = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // PENGHASIL SUARA SINTETIS FALLBACK (Jika berkas di laptop benar-benar tidak ada)
  Future<List<int>> _generateFallbackWavBytes(String label) async {
    const int sampleRate = 8000;
    final double frequency =
        label.toLowerCase().contains('chainsaw') ? 180.0 : 440.0;
    const double durationSeconds = 3.0;
    final int numSamples = (durationSeconds * sampleRate).toInt();

    final List<int> pcmData = [];
    for (int i = 0; i < numSamples; i++) {
      double t = i / sampleRate;
      double sample = sin(2 * pi * frequency * t);
      if (label.toLowerCase().contains('chainsaw')) {
        sample += (i % 20 == 0) ? 0.5 : -0.5;
      }
      int intSample = (sample * 32767).toInt().clamp(-32768, 32767);

      pcmData.add(intSample & 0xFF);
      pcmData.add((intSample >> 8) & 0xFF);
    }

    final List<int> header = [];
    header.addAll([0x52, 0x49, 0x46, 0x46]);
    int fileSize = 36 + pcmData.length;
    header.addAll([
      fileSize & 0xFF,
      (fileSize >> 8) & 0xFF,
      (fileSize >> 16) & 0xFF,
      (fileSize >> 24) & 0xFF
    ]);
    header.addAll([0x57, 0x41, 0x56, 0x45]);
    header.addAll([0x66, 0x6D, 0x74, 0x20]);
    header.addAll([16, 0, 0, 0]);
    header.addAll([1, 0]);
    header.addAll([1, 0]);
    header.addAll([
      sampleRate & 0xFF,
      (sampleRate >> 8) & 0xFF,
      (sampleRate >> 16) & 0xFF,
      (sampleRate >> 24) & 0xFF
    ]);
    int byteRate = sampleRate * 1 * 2;
    header.addAll([
      byteRate & 0xFF,
      (byteRate >> 8) & 0xFF,
      (byteRate >> 16) & 0xFF,
      (byteRate >> 24) & 0xFF
    ]);
    header.addAll([2, 0]);
    header.addAll([16, 0]);
    header.addAll([0x64, 0x61, 0x74, 0x61]);
    int dataSize = pcmData.length;
    header.addAll([
      dataSize & 0xFF,
      (dataSize >> 8) & 0xFF,
      (dataSize >> 16) & 0xFF,
      (dataSize >> 24) & 0xFF
    ]);

    return [...header, ...pcmData];
  }

  String _extractFilename(String rawUrl) {
    String value = rawUrl;
    if (value.contains(r'\')) {
      value = value.split(r'\').last;
    } else {
      value = value.split('/').last;
    }
    if (value.contains('?')) {
      value = value.split('?').first;
    }
    return value;
  }

  /// 🚀 RESOLVER URL DIPERBAIKI:
  /// Memaksa penggunaan endpoint /static-audio/ lokal laptop apabila URL
  /// mengarah ke Supabase, path lokal, ATAU ke "localhost"/"127.0.0.1"
  /// (host tersebut TIDAK BOLEH dipercaya dari sisi HP — di HP, "localhost"
  /// selalu berarti HP itu sendiri, bukan laptop server. Sebelumnya kondisi
  /// ini tidak dicek, sehingga URL "http://localhost:8000/..." lolos apa
  /// adanya dan HP mencoba connect ke dirinya sendiri -> Connection refused).
  String _resolveAudioUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    final lower = trimmed.toLowerCase();

    final bool isUntrustedHost =
        lower.contains("localhost") || lower.contains("127.0.0.1");

    if (trimmed.contains("supabase.co") ||
        trimmed.startsWith("local://") ||
        !trimmed.startsWith("http") ||
        isUntrustedHost) {
      final cleanFilename = _extractFilename(trimmed);
      return "$kFallbackAiServerBaseUrl/static-audio/$cleanFilename";
    }

    return trimmed;
  }

  Future<void> _togglePlayAudio(String? url, int index, String label) async {
    if (url == null || url.isEmpty || url.contains('TIDAK_TERSEDIA')) {
      _showSnackBar(
          "⚠️ File rekaman audio tidak tersedia di server.", AppTheme.danger);
      return;
    }

    final String cleanFilename = _extractFilename(url);
    final String secureUrl = _resolveAudioUrl(url);

    try {
      if (_playingIndex == index) {
        await _audioPlayer.pause();
        setState(() {
          _playingIndex = null;
        });
        return;
      }

      await _audioPlayer.stop();
      setState(() {
        _isLoadingAudio = true;
        _playingIndex = index;
      });

      List<int>? targetBytes;

      try {
        debugPrint("📡 HP Mengunduh Rekaman Asli Hutan Dari: $secureUrl");
        final response = await http
            .get(Uri.parse(secureUrl))
            .timeout(const Duration(seconds: 10));

        debugPrint(
            "📥 [HTTP Response] status=${response.statusCode} content-length=${response.bodyBytes.length} bytes untuk $secureUrl");

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          targetBytes = response.bodyBytes;
        } else {
          debugPrint(
              "❌ File statis gagal dimuat (HTTP ${response.statusCode}) dari $secureUrl");
        }
      } catch (networkError) {
        debugPrint(
            "🚨 Masalah koneksi jaringan lokal antara HP ke Laptop ($secureUrl): $networkError");
      }

      final tempDir = await getTemporaryDirectory();
      final String safeName = cleanFilename.isNotEmpty
          ? cleanFilename
          : 'fallback_${label}_$index.wav';
      final file = File('${tempDir.path}/pkm_rec_$safeName');

      if (targetBytes != null && targetBytes.isNotEmpty) {
        await file.writeAsBytes(targetBytes, flush: true);
        debugPrint(
            "🔥 KONEKSI BERHASIL: Memutar rekaman audio asli ($cleanFilename)");
        if (mounted) {
          _showSnackBar(
              "🔊 Memutar rekaman asli dari hutan...", AppTheme.primary);
        }
      } else {
        final fallbackBytes = await _generateFallbackWavBytes(label);
        await file.writeAsBytes(fallbackBytes, flush: true);
        debugPrint(
            "🚨 Mengaktifkan Fallback Audio Engine HP untuk simulasi ($label)");
        if (mounted) {
          _showSnackBar(
              "🔔 Rekaman asli gagal dimuat (Cek Jaringan Lokal), memutar audio simulasi",
              AppTheme.danger);
        }
      }

      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
        });
      }

      await _audioPlayer.play(DeviceFileSource(file.path));
    } catch (e) {
      debugPrint("Gagal memutar audio: $e");
      if (mounted) {
        setState(() {
          _playingIndex = null;
          _isLoadingAudio = false;
        });
      }
      _showSnackBar(
          "❌ Hardware media HP sibuk. Coba sekali lagi.", AppTheme.danger);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "Tidak ada rekaman aktivitas suara terdeteksi.",
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = widget.events[index];
        final String rawLabel = item['label']?.toString() ?? 'Silence';
        final double score =
            double.tryParse(item['predictionScore']?.toString() ?? '0.0') ??
                0.0;
        final String? audioUrl = item['audioUrl']?.toString();

        final style = AudioVisualHelper.getStyle(rawLabel);
        final bool isCurrentPlaying = _playingIndex == index;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: style['bg'],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: style['border']),
          ),
          child: Row(
            children: [
              Text(style['icon'], style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style['label'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Akurasi AI: ${(score * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: (_isLoadingAudio && isCurrentPlaying)
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      )
                    : Icon(
                        isCurrentPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        color: isCurrentPlaying
                            ? AppTheme.danger
                            : AppTheme.primary,
                        size: 32,
                      ),
                onPressed: _isLoadingAudio
                    ? null
                    : () => _togglePlayAudio(audioUrl, index, style['label']),
              ),
            ],
          ),
        );
      },
    );
  }
}
