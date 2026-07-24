// File: src/app/api/mobile/node/route.ts
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getMobileAuthUser } from '@/lib/mobile-auth';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const authUser = getMobileAuthUser(req);
    if (!authUser) return mobileFail('Sesi tidak valid, silakan login kembali', 401);

    const nodes = await prisma.deviceNode.findMany({
      include: {
        sensorReadings: {
          orderBy: { recordedAt: 'desc' },
          take: 1,
        },
      },
      orderBy: { nodeCode: 'asc' },
    });

    // Format data agar ramah pembacaan Flutter
    const formattedNodes = nodes.map((node) => {
      const latestReading = node.sensorReadings.length > 0 ? node.sensorReadings[0] : null;

      return {
        id: node.id,
        nodeCode: node.nodeCode,
        name: node.name,
        locationName: node.locationName || 'Kawasan Hutan Rimbarest',
        latitude: node.latitude ? Number(node.latitude) : -2.129486,
        longitude: node.longitude ? Number(node.longitude) : 106.113042,
        status: node.status, // ONLINE / OFFLINE
        latestReading: latestReading ? {
          pm25: Number(latestReading.pm25 ?? 0),
          pm10: Number(latestReading.pm10 ?? 0),
          noiseLevel: Number(latestReading.noiseLevel ?? 0),
          statusTerpadu: latestReading.statusTerpadu || '✅ Normal Bersih',
          recordedAt: latestReading.recordedAt,
        } : null
      };
    });

    return mobileOk(formattedNodes, 'Daftar node berhasil diambil', 200);
  } catch (error: any) {
    console.error('❌ [MOBILE][node][GET] Error:', error);
    return mobileFail(error.message || 'Terjadi kesalahan pada server', 500);
  }
}