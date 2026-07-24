// Endpoint mobile: GET /api/mobile/prediksi-ai-audio
// Query opsional: ?nodeCode=NODE-001&limit=20
// Daftar hasil prediksi/klasifikasi AI audio (AudioIncident) untuk halaman "Prediksi AI Audio".
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getMobileAuthUser } from '@/lib/mobile-auth';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const authUser = getMobileAuthUser(req);
    if (!authUser) return mobileFail('Sesi tidak valid, silakan login kembali', 401);

    const { searchParams } = new URL(req.url);
    const nodeCode = searchParams.get('nodeCode');
    const limit = Math.min(parseInt(searchParams.get('limit') || '20', 10) || 20, 200);

    let nodeId: string | undefined;
    if (nodeCode) {
      const node = await prisma.deviceNode.findUnique({ where: { nodeCode } });
      if (!node) return mobileFail('Node tidak ditemukan', 404);
      nodeId = node.id;
    }

    const predictions = await prisma.audioIncident.findMany({
      where: nodeId ? { nodeId } : undefined,
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: {
        node: { select: { name: true, nodeCode: true } },
        sensorReading: { select: { noiseLevel: true, recordedAt: true } },
      },
    });

    return mobileOk(predictions, 'Riwayat prediksi AI audio berhasil diambil', 200);
  } catch (error: any) {
    console.error('❌ [MOBILE][prediksi-ai-audio] Error:', error);
    return mobileFail(error.message || 'Terjadi kesalahan pada server', 500);
  }
}
