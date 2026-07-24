// Endpoint mobile: POST /api/mobile/login-register/login
// Dipakai oleh AuthService.login() di aplikasi Flutter.
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import bcrypt from 'bcryptjs';
import { signToken } from '@/lib/jwt';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    // Flutter mengirim field "usernameOrEmail", tapi tetap dukung "username"/"email" langsung.
    const identifier: string | undefined =
      body.usernameOrEmail || body.username || body.email;
    const password: string | undefined = body.password;

    if (!identifier || !password) {
      return mobileFail('Username/email dan password wajib diisi', 400);
    }

    const user = await prisma.user.findFirst({
      where: { OR: [{ username: identifier }, { email: identifier }] },
    });

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return mobileFail('Username/email atau password salah', 401);
    }

    if (!user.isActive) {
      return mobileFail('Akun Anda dinonaktifkan, hubungi admin', 403);
    }

    const token = signToken({ id: user.id, username: user.username, role: user.role });

    return mobileOk(
      {
        token,
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          phone: user.phone,
          role: user.role,
          photo: user.photo,
          address: user.address,
          locationEnabled: user.locationEnabled,
          nightMode: user.nightMode,
          notificationEnabled: user.notificationEnabled,
          syncInterval: user.syncInterval,
        },
      },
      'Login sukses',
      200,
    );
  } catch (error: any) {
    console.error('❌ [MOBILE][login] Error:', error);
    return mobileFail(error.message || 'Terjadi kesalahan pada server', 500);
  }
}
