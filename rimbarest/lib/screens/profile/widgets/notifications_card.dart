// File: lib/screens/profile/widgets/notifications_card.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class NotificationsCard extends StatelessWidget {
  final bool notifEnabled;
  final List<dynamic> notifications;
  final Future<void> Function(int id) onRead;

  const NotificationsCard({
    super.key,
    required this.notifEnabled,
    required this.notifications,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 SINKRONISASI MARGIN LUAR: Dibuat pas dengan tata letak container lainnya
    const cardMargin = EdgeInsets.symmetric(horizontal: 0, vertical: 0);

    // 1. Tampilan jika Fitur Push Notification dinonaktifkan
    if (!notifEnabled) {
      return Container(
        margin: cardMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSoft),
        ),
        child: const Text(
          "Notifikasi sedang nonaktif.",
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    // 2. Tampilan jika Daftar Notifikasi Kosong murni
    if (notifications.isEmpty) {
      return Container(
        margin: cardMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSoft),
        ),
        child: const Text(
          "Belum ada notifikasi terbaru.",
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    // 🚀 FILTERING DATA: Mengambil 2 Audio Terkini & 2 Partikulat Terkini
    final audioNotifications = notifications
        .where((n) {
          final type = (n["type"] ?? "").toString().toUpperCase();
          final title = (n["title"] ?? "").toString().toLowerCase();
          final msg = (n["message"] ?? "").toString().toLowerCase();

          return type == "AUDIO" ||
              type == "DANGER" ||
              title.contains("suara") ||
              title.contains("bahaya") ||
              msg.contains("chainsaw") ||
              msg.contains("terdeteksi");
        })
        .take(2)
        .toList();

    final particulateNotifications = notifications
        .where((n) {
          final type = (n["type"] ?? "").toString().toUpperCase();
          final title = (n["title"] ?? "").toString().toLowerCase();
          final msg = (n["message"] ?? "").toString().toLowerCase();

          return type == "PARTIKULAT" ||
              type == "ASAP" ||
              title.contains("partikulat") ||
              title.contains("asap") ||
              title.contains("pm2") ||
              msg.contains("udara");
        })
        .take(2)
        .toList();

    final filteredNotifications = [
      ...audioNotifications,
      ...particulateNotifications
    ];

    // Fallback jika setelah difilter data spesifik tidak ditemukan
    if (filteredNotifications.isEmpty) {
      return Container(
        margin: cardMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSoft),
        ),
        child: const Text(
          "Tidak ada notifikasi audio atau partikulat terbaru.",
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    // 3. Tampilan Utama Container List (Sudah Diratakan Sempurna)
    return Container(
      margin: cardMargin,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSoft),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets
            .zero, // Bersihkan padding default ListView agar tidak jomplang
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredNotifications.length,
        separatorBuilder: (_, __) => _divider(),
        itemBuilder: (context, index) {
          final n = filteredNotifications[index];
          final isUnread = n["status"] == "belum_dibaca";
          final id = n["id"];

          final titleLower = (n["title"] ?? "").toString().toLowerCase();
          final isPartikulatType = titleLower.contains("partikulat") ||
              titleLower.contains("asap") ||
              titleLower.contains("pm2");

          return Padding(
            // 🚀 PENYESUAIAN PADDING DALAM: Agar teks sejajar rapi dengan baris pengaturan di atasnya
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ikon Box Kiri
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isUnread
                        ? AppTheme.danger.withValues(alpha: 0.1)
                        : AppTheme.bgPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPartikulatType
                        ? Icons.cloud_rounded
                        : Icons.hearing_rounded,
                    color: isUnread ? AppTheme.danger : AppTheme.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 11),
                // Konten Teks Tengah
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        n["title"] ?? "-",
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        n["message"] ?? "-",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Aksi Kanan
                isUnread
                    ? TextButton(
                        onPressed: id == null
                            ? null
                            : () => onRead(int.parse(id.toString())),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        child: const Text("Baca"),
                      )
                    : const Icon(
                        Icons.check_circle,
                        color: Color(0xFF2ECC71),
                        size: 16,
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppTheme.borderSoft,
    );
  }
}
