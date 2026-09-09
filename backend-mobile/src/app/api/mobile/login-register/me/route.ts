// Path: D:\flutter\project\PKM_KC\backend-mobile\src\app\api\mobile\login-register\me\route.ts
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getMobileAuthUser } from '@/lib/mobile-auth';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const authUser = getMobileAuthUser(req);
    if (!authUser) return mobileFail('Sesi tidak valid, silakan login kembali', 401);

    const user = await prisma.user.findUnique({
      where: { id: authUser.id },
      select: {
        id: true,
        username: true,
        email: true,
        firstName: true,
        lastName: true,
        phone: true,
        role: true,
        photo: true,
        address: true,
        locationEnabled: true,
        nightMode: true,
        notificationEnabled: true,
        syncInterval: true,
        createdAt: true,
      },
    });

    if (!user) return mobileFail('User tidak ditemukan', 404);

    return mobileOk(user, 'Profil berhasil diambil', 200);
  } catch (error: any) {
    console.error('❌ [MOBILE][me][GET] Error:', error);
    return mobileFail(error.message || 'Terjadi kesalahan pada server', 500);
  }
}

export async function PUT(req: NextRequest) {
  try {
    const authUser = getMobileAuthUser(req);
    if (!authUser) return mobileFail('Sesi tidak valid, silakan login kembali', 401);

    const body = await req.json();
    const {
      firstName,
      lastName,
      phone,
      address,
      photo,
      locationEnabled,
      nightMode,
      notificationEnabled,
      syncInterval,
    } = body;

    // 🚀 FIX UTAMA: Validasi super ketat agar nilai 'null' dari Flutter tidak merusak skema PostgreSQL
    const updateData: any = {};

    if (firstName !== undefined && firstName !== null) updateData.firstName = firstName.toString();
    if (lastName !== undefined && lastName !== null) updateData.lastName = lastName.toString();
    if (phone !== undefined && phone !== null) updateData.phone = phone.toString();
    if (address !== undefined && address !== null) updateData.address = address.toString().trim();
    if (photo !== undefined && photo !== null) updateData.photo = photo.toString();

    // Pastikan type data Boolean dikonversi dengan aman & tidak boleh bernilai null
    if (locationEnabled !== undefined && locationEnabled !== null && locationEnabled !== 'null') {
      updateData.locationEnabled = String(locationEnabled) === 'true';
    }
    if (nightMode !== undefined && nightMode !== null && nightMode !== 'null') {
      updateData.nightMode = String(nightMode) === 'true';
    }
    if (notificationEnabled !== undefined && notificationEnabled !== null && notificationEnabled !== 'null') {
      updateData.notificationEnabled = String(notificationEnabled) === 'true';
    }
    if (syncInterval !== undefined && syncInterval !== null && syncInterval !== 'null') {
      updateData.syncInterval = syncInterval.toString();
    }

    const updatedUser = await prisma.user.update({
      where: { id: authUser.id },
      data: updateData, // Gunakan objek yang sudah difilter bersih dari null
      select: {
        id: true,
        username: true,
        email: true,
        firstName: true,
        lastName: true,
        phone: true,
        role: true,
        photo: true,
        address: true,
        locationEnabled: true,
        nightMode: true,
        notificationEnabled: true,
        syncInterval: true,
      },
    });

    return mobileOk(updatedUser, 'Profil berhasil diperbarui', 200);
  } catch (error: any) {
    console.error('❌ [MOBILE][me][PUT] Error:', error);
    return mobileFail(error.message || 'Terjadi kesalahan pada server', 500);
  }
}