import prisma from './prisma';

/**
 * 🌟 BARU — Helper untuk mencatat riwayat notifikasi in-app (tabel Notification)
 * yang dikonsumsi oleh endpoint /api/mobile/notifikasi di aplikasi Flutter.
 * Dibuat terpisah dari services/notification.ts (pengirim FCM) supaya
 * alur push-notification yang sudah berjalan sempurna ke IoT/Web TIDAK disentuh sama sekali.
 * Fungsi ini sengaja "fail-safe": kalau gagal insert, hanya di-log, tidak melempar error,
 * supaya proses utama (simpan sensor reading, insiden audio, dsb) tidak pernah ikut gagal.
 */
export async function createNotification(params: {
  userId?: string | null;
  nodeId?: string | null;
  title: string;
  message?: string;
  type?: 'INFO' | 'WARNING' | 'DANGER';
}) {
  try {
    await prisma.notification.create({
      data: {
        userId: params.userId ?? null,
        nodeId: params.nodeId ?? null,
        title: params.title,
        message: params.message ?? null,
        type: params.type ?? 'INFO',
      },
    });
  } catch (error) {
    console.error('[Notification] Gagal mencatat riwayat notifikasi in-app:', error);
  }
}
