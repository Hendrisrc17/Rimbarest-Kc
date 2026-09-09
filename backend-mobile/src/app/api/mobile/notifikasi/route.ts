// File: src/app/api/mobile/notifikasi/route.ts
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getMobileAuthUser } from '@/lib/mobile-auth';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const authUser = getMobileAuthUser(req);
    if (!authUser) return mobileFail('Sesi tidak valid, silakan login kembali', 401);

    const { searchParams } = new URL(req.url);
    const statusParam = searchParams.get('status'); // 'belum_dibaca' | 'dibaca'
    const limit = Math.min(parseInt(searchParams.get('limit') || '50', 10) || 50, 200);

    // Konversi parameter pencarian dari Flutter (Bahasa Indonesia) ke standar DB (Bahasa Inggris)
    let dbStatusCondition: any = undefined;
    if (statusParam === 'belum_dibaca') {
      dbStatusCondition = { in: ['UNREAD', 'unread', 'belum_dibaca'] };
    } else if (statusParam === 'dibaca') {
      dbStatusCondition = { in: ['READ', 'read', 'dibaca'] };
    }

    const notifications = await prisma.notification.findMany({
      where: {
        OR: [
          { userId: authUser.id }, 
          { userId: null } // Agar notifikasi publik dari IoT cURL otomatis masuk ke aplikasi siapa pun yang login
        ],
        ...(dbStatusCondition ? { status: dbStatusCondition } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: { node: { select: { name: true, nodeCode: true } } },
    });

    // 🚀 DATA TRANSFORMER LENGKAP: Konversi status & pastikan type terbaca sempurna oleh Flutter
    const sanitizedNotifications = notifications.map((n: any) => {
      const currentStatus = String(n.status).toUpperCase();
      const titleText = String(n.title).toLowerCase();
      
      // Deteksi dinamis fallback tipe jika di DB tipenya masih polos/DANGER bawaan awal
      let notificationType = n.type || 'INFO';
      if (titleText.includes('asap') || titleText.includes('partikulat')) {
        notificationType = 'PARTIKULAT';
      } else if (titleText.includes('bahaya') || titleText.includes('chainsaw')) {
        notificationType = 'AUDIO';
      }

      return {
        ...n,
        // Jika statusnya UNREAD, kirim ke Flutter sebagai "belum_dibaca"
        status: (currentStatus === 'UNREAD' || currentStatus === 'BELUM_DIBACA') ? 'belum_dibaca' : 'dibaca',
        // Pastikan field type terlempar agar ditangkap widget ikon di Flutter profil lu
        type: notificationType,
      };
    });

    const unreadCount = await prisma.notification.count({
      where: { 
        status: { in: ['UNREAD', 'unread', 'belum_dibaca'] } as any, 
        OR: [{ userId: authUser.id }, { userId: null }] 
      },
    });

    return mobileOk(
      { notifications: sanitizedNotifications, unreadCount }, 
      'Daftar notifikasi berhasil diambil', 
      200
    );
  } catch (error: any) {
    console.error('❌ [MOBILE][notifikasi][GET] Error:', error);
    return mobileFail(error.message || 'Terjadi kesalahan pada server', 500);
  }
}

export async function PUT(req: NextRequest) {
  try {
    const authUser = getMobileAuthUser(req);
    if (!authUser) return mobileFail('Sesi tidak valid, silakan login kembali', 401);

    const body = await req.json();
    const { id, markAllRead } = body;

    if (markAllRead) {
      // Ambil nilai enum asli database atau string lowercase/uppercase agar update massal aman
      await prisma.notification.updateMany({
        where: {
          status: { in: ['UNREAD', 'unread', 'belum_dibaca'] } as any,
          OR: [{ userId: authUser.id }, { userId: null }],
        },
        data: { status: 'READ' as any }, // Setel kembali ke format default database
      });
      return mobileOk(null, 'Semua notifikasi ditandai sudah dibaca', 200);
    }

    if (!id) return mobileFail('Parameter id atau markAllRead diperlukan', 400);

    const finalId = isNaN(parseInt(id.toString(), 10)) ? id.toString() : parseInt(id.toString(), 10);

    // Cari tahu dulu notifikasi tersebut ada atau tidak sebelum diupdate
    const existingNotif = await prisma.notification.findUnique({
      where: { id: finalId as any }
    });

    if (!existingNotif) {
      return mobileFail('Notifikasi tidak ditemukan', 404);
    }

    // Update status satuan ke format default database
    const updated = await prisma.notification.update({
      where: { id: finalId as any },
      data: { status: 'READ' as any },
    });

    // Kembalikan objek yang sudah disanitasi ke Flutter agar UI tombol langsung berubah jadi centang hijau
    const sanitizedUpdated = {
      ...updated,
      status: 'dibaca'
    };

    return mobileOk(sanitizedUpdated, 'Notifikasi ditandai sudah dibaca', 200);
  } catch (error: any) {
    console.error('❌ [MOBILE][notifikasi][PUT] Error:', error);
    return mobileFail(error.message || 'Terjadi kesalahan pada server', 500);
  }
}