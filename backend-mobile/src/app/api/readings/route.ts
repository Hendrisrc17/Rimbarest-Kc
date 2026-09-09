import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const limit = parseInt(searchParams.get('limit') || '50');

    const readings = await prisma.sensorReading.findMany({
      orderBy: { recordedAt: 'desc' },
      take: limit,
      include: {
        node: { select: { name: true, nodeCode: true } }
      }
    });

    return NextResponse.json(readings, { status: 200 });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}