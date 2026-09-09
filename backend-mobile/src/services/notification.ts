// File: src/services/notification.ts
import prisma from '@/lib/prisma';
import { messaging } from './firebase';

export async function sendPushNotification(title: string, body: string) {
  if (!messaging) {
    console.warn('Gagal kirim notifikasi: Firebase Messaging tidak aktif.');
    return;
  }

  try {
    // 1. Mengambil semua device token aktif yang terdaftar di database
    const activeTokens = await prisma.deviceToken.findMany({
      where: { isActive: true },
      select: { token: true }
    });

    if (activeTokens.length === 0) {
      console.log('Tidak ada device token terdaftar.');
      return;
    }

    const tokensList = activeTokens.map((t: { token: string }) => t.token);

    // 2. Menyusun payload notifikasi prioritas tinggi (Heads-Up Banner)
    const message = {
      notification: { title, body },
      
      // 🚀 KONFIGURASI UNTUK ANDROID (SINKRON DENGAN FLUTTER & TYPE-SAFE)
      android: {
        priority: 'high' as const, // Memaksa pesan langsung dikirim tanpa delay oleh OS
        notification: {
          channelId: 'rimbarest_alerts', // Wajib sama dengan channel ID di Flutter
          sound: 'default',              // Memicu bunyi "Ting" bawaan sistem
          priority: 'max' as const,       // Memaksa OS memunculkan banner melayang (Heads-up)
          visibility: 'public' as const,   // Menjamin notifikasi tembus saat layar terkunci
        },
      },
      
      // 🚀 KONFIGURASI UNTUK IOS (APNS)
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
          },
        },
        headers: {
          'apns-priority': '10', // Prioritas tertinggi untuk iOS
        },
      },
      
      // Data tambahan yang dibawa ke sisi aplikasi Flutter
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        status: 'danger',
        timestamp: new Date().toISOString(),
      },
      tokens: tokensList,
    };

    // 3. Eksekusi pengiriman massal ke seluruh token terdaftar
    const response = await messaging.sendEachForMulticast(message);
    console.log(`Notifikasi terkirim sukses: ${response.successCount}`);

    // 4. Logika Pembersihan otomatis jika ditemukan token yang sudah expired/tidak valid
    if (response.failureCount > 0) {
      response.responses.forEach((resp: { success: boolean; error?: any }, idx: number) => {
        if (!resp.success && resp.error) {
          const invalidToken = tokensList[idx];
          if (
            resp.error.code === 'messaging/invalid-registration-token' ||
            resp.error.code === 'messaging/registration-token-not-registered'
          ) {
            // Jalankan penghapusan token usang dari database PostgreSQL
            prisma.deviceToken.deleteMany({ where: { token: invalidToken } })
              .then(() => console.log(`Token usang dihapus secara otomatis: ${invalidToken}`))
              .catch((err: any) => console.error('Gagal menghapus token usang:', err));
          }
        }
      });
    }
  } catch (error) {
    console.error('Error saat mengeksekusi pengiriman notifikasi:', error);
  }
}