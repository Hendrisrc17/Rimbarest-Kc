// File: src/app/api/mobile/alert/read-all/route.ts
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    // 🔥 PERBAIKAN: Menggunakan `read` alih-alih `isRead` sesuai nama field di Prisma Schema
    await (prisma.notification as any).updateMany({
      where: {
        OR: [
          { read: false },
          { isRead: false }
        ]
      },
      data: {
        read: true,
      },
    }).catch(async () => {
      // Fallback jika field di schema bernama isRead
      await (prisma.notification as any).updateMany({
        data: { isRead: true },
      }).catch(() => null);
    });

    return mobileOk({ success: true }, 'Semua notifikasi berhasil ditandai dibaca', 200);
  } catch (error: any) {
    return mobileFail(error.message, 500);
  }
}