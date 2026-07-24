import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class StatusBanner extends StatelessWidget {
  // 🌟 TERKONEKSI SISTEM & BACKEND: Menerima data summary dan status keandalan server
  final Map<String, dynamic>? data;
  final bool isServerOffline;

  const StatusBanner({
    super.key,
    this.data,
    this.isServerOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Ekstraksi data agregasi node dari sub-objek summary
    final summary = data?['summary'] ?? {};
    final int offlineNodes = summary['offlineNodes'] ?? 0;

    // 2. Evaluasi status peringatan sistem
    // Peringatan aktif jika server mati total ATAU jika ada node sensor di database yang mati
    final bool hasAlert = isServerOffline || offlineNodes > 0;

    // 3. Setel pesan teks peringatan secara otomatis dan dinamis
    String alertMessage = 'Sistem Beroperasi Normal';
    if (isServerOffline) {
      alertMessage = 'Koneksi Server Terputus (Offline)';
    } else if (offlineNodes > 0) {
      alertMessage = 'Terdeteksi $offlineNodes Perangkat Mati';
    } else if (data?['statusTerpadu'] != null) {
      alertMessage = data!['statusTerpadu'].toString();
    }

    // 4. Setel pewarnaan aksen visual UI berdasarkan tingkat urgensi
    Color statusColor = AppTheme.success;
    IconData statusIcon = Icons.check_circle_rounded;

    if (isServerOffline) {
      statusColor = AppTheme.danger; // Merah jika server laptop mati
      statusIcon = Icons.cloud_off_rounded;
    } else if (offlineNodes > 0) {
      statusColor = AppTheme.warning; // Kuning jika hanya beberapa node mati
      statusIcon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderMedium),
        boxShadow: [
          BoxShadow(
            color: (isServerOffline ? AppTheme.danger : AppTheme.primary)
                .withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatusInfo(
              message: alertMessage,
              statusColor: statusColor,
              statusIcon: statusIcon,
            ),
          ),
          _NodeCounter(
            isServerOffline: isServerOffline,
            hasAlert: hasAlert,
            disconnectedCount: offlineNodes,
          ),
        ],
      ),
    );
  }
}

class _StatusInfo extends StatelessWidget {
  final String message;
  final Color statusColor;
  final IconData statusIcon;

  const _StatusInfo({
    required this.message,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    // 🌟 SINKRONISASI JAM & TANGGAL: Selalu mengambil waktu terbaru perangkat saat di-refresh otomatis
    final now = DateTime.now();
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final String formattedDate =
        "${now.day} ${months[now.month - 1]} ${now.year} · ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          formattedDate,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _NodeCounter extends StatelessWidget {
  final bool isServerOffline;
  final bool hasAlert;
  final int disconnectedCount;

  const _NodeCounter({
    required this.isServerOffline,
    required this.hasAlert,
    required this.disconnectedCount,
  });

  @override
  Widget build(BuildContext context) {
    String counterText = 'OK';
    String labelText = 'Semua Online';
    Color counterColor = AppTheme.primary;

    if (isServerOffline) {
      counterText = 'ERR';
      labelText = 'Server Down';
      counterColor = AppTheme.danger;
    } else if (disconnectedCount > 0) {
      counterText = '-$disconnectedCount';
      labelText = 'Node Mati';
      counterColor = AppTheme.warning;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          counterText,
          style: TextStyle(
            color: counterColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          labelText,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
