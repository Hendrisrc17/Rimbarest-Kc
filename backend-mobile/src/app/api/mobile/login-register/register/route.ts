// Endpoint mobile: POST /api/mobile/login-register/register
// Dipakai oleh AuthService.register() di aplikasi Flutter.
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import bcrypt from 'bcryptjs';
import { signToken } from '@/lib/jwt';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { firstName, lastName, username, email, phone, password } = body;

    if (!username || !email || !password) {
      return mobileFail('Username, email, dan password wajib diisi', 400);
    }

    const existingUser = await prisma.user.findFirst({
      where: { OR: [{ email }, { username }] },
    });

    if (existingUser) {
      return mobileFail('Email atau Username sudah terdaftar', 400);
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await prisma.user.create({
      data: {
        username,
        email,
        password: hashedPassword,
        firstName: firstName || null,
        lastName: lastName || null,
        phone: phone || null,
        role: 'PENGGUNA',
      },
    });

    // Langsung buatkan token supaya Flutter bisa auto-login setelah registrasi.
    const token = signToken({ id: newUser.id, username: newUser.username, role: newUser.role });

    return mobileOk(
      {
        token,
        user: {
          id: newUser.id,
          username: newUser.username,
          email: newUser.email,
          firstName: newUser.firstName,
          lastName: newUser.lastName,
          phone: newUser.phone,
          role: newUser.role,
        },
      },
      'Registrasi berhasil',
      201,
    );
  } catch (error: any) {
    console.error('❌ [MOBILE][register] Error:', error);
    return mobileFail(error.message || 'Terjadi kesalahan pada server', 500);
  }
}
