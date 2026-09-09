// Path: D:\flutter\project\PKM_KC\backend-mobile\src\app\api\mobile\profile\token\route.ts
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getMobileAuthUser } from '@/lib/mobile-auth';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    // 1. Validasi Sesi user JWT dari middleware mobile
    const authUser = getMobileAuthUser(req);
    if (!authUser) {
      return mobileFail('Sesi tidak valid, silakan login kembali', 401);
    }

    // 2. Ekstraksi data FCM Token dan Platform dari request body
    const { fcmToken, platform } = await req.json();
    if (!fcmToken) {
      return mobileFail('fcmToken diperlukan untuk menerima peringatan bahaya', 400);
    }

    // 3. Normalisasi data platform agar sesuai dengan standarisasi database
    const devicePlatform = platform ? platform.toString().toUpperCase() : 'ANDROID';

    // 4. Proses Upsert (Update jika token perangkat sudah ada, Create jika token baru)
    const deviceToken = await prisma.deviceToken.upsert({
      where: { 
        token: fcmToken 
      },
      update: { 
        userId: authUser.id, 
        platform: devicePlatform, 
        isActive: true 
      },
      create: { 
        userId: authUser.id, 
        token: fcmToken, 
        platform: devicePlatform, 
        isActive: true 
      },
    });

    // 5. Kembalikan envelope response format mobile ({ success: true, message: ..., data: ... })
    return mobileOk(
      { id: deviceToken.id }, 
      'FCM device token berhasil disinkronkan', 
      200
    );

  } catch (error: any) {
    // Mencetak log error asli di terminal backend Next.js kamu untuk mempermudah debugging
    console.error('❌ [MOBILE][profile/token] Error:', error);
    return mobileFail(error.message || 'Terjadi kesalahan internal pada server', 500);
  }
}