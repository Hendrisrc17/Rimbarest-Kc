// Endpoint mobile: GET /api/mobile/node/[nodeCode]
// Detail satu node: 10 bacaan sensor terakhir (untuk mini-chart) + 5 insiden audio terakhir.
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getMobileAuthUser } from '@/lib/mobile-auth';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest, { params }: { params: Promise<{ nodeCode: string }> }) {
  try {
    const authUser = getMobileAuthUser(req);
    if (!authUser) return mobileFail('Sesi tidak valid, silakan login kembali', 401);

    const { nodeCode } = await params;

    const nodeDetails = await prisma.deviceNode.findUnique({
      where: { nodeCode },
      include: {
        sensorReadings: {
          orderBy: { recordedAt: 'desc' },
          take: 10,
        },
        audioIncidents: {
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
      },
    });

    if (!nodeDetails) return mobileFail('Node tidak ditemukan', 404);

    return mobileOk(nodeDetails, 'Detail node berhasil diambil', 200);
  } catch (error: any) {
    console.error('❌ [MOBILE][node/nodeCode] Error:', error);
    return mobileFail(error.message || 'Terjadi kesalahan pada server', 500);
  }
}
