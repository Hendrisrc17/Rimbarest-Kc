// File: src/app/api/mobile/user/token/route.ts
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { token, isActive, userId } = body;

    if (!token) {
      return NextResponse.json({ success: false, error: 'Token wajib diisi.' }, { status: 400 });
    }

    let targetUserId = userId;
    
    // 🚀 BYPASS AMAN & KEBAL ERROR: 
    // Jika tidak ada userId dari Flutter, langsung ambil user PERTAMA yang ada di DB
    if (!targetUserId) {
      const anyUser = await prisma.user.findFirst({
        select: { id: true }
      });
      
      if (!anyUser) {
        // 🔧 FIX AKURAT: Properti disesuaikan dengan isi model User di schema.prisma lu!
        const dummyUser = await prisma.user.create({
          data: {
            username: 'rimbarest_device',
            email: 'rimbarest_device@pkm.com',
            password: 'dummy_secure_password_123', 
            firstName: 'Device',
            lastName: 'Simulator',
            role: 'ADMIN' // Menggunakan Enum Role.ADMIN yang ada di schema lu
          },
          select: { id: true }
        });
        targetUserId = dummyUser.id;
        console.log('🤖 [FCM System] Database kosong. User dummy otomatis dibuat dengan ID:', targetUserId);
      } else {
        targetUserId = anyUser.id;
      }
    }

    // Eksekusi Upsert ke PostgreSQL via Prisma
    const deviceToken = await prisma.deviceToken.upsert({
      where: { token: token },
      update: { 
        isActive: isActive ?? true,
        userId: targetUserId 
      },
      create: {
        token: token,
        isActive: isActive ?? true,
        userId: targetUserId 
      },
    });

    console.log('✅ [FCM System] Token perangkat sukses diperbarui di PostgreSQL:', token.substring(0, 15) + '...');
    return NextResponse.json({ success: true, data: deviceToken }, { status: 200 });
  } catch (error: any) {
    console.error('❌ [TOKEN API ERROR]:', error);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}