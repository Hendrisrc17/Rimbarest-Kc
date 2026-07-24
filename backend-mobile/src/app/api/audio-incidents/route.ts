// File: src/app/api/audio-incidents/route.ts
import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

// 🚀 FIX UTAMA: Paksa API melakukan Live Query ke PostgreSQL setiap kali dipanggil oleh Flutter
export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const incidents = await prisma.audioIncident.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        node: { 
          select: { name: true, nodeCode: true } 
        },
        sensorReading: { 
          select: { noiseLevel: true } 
        }
      }
    });

    return NextResponse.json(incidents, { status: 200 });
  } catch (error: any) {
    console.error('❌ [AUDIO-INCIDENTS-GET] Gagal memuat riwayat:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}