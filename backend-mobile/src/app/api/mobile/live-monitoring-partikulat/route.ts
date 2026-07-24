import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';

// Fungsi bantu untuk menentukan status AI secara real-time berdasarkan nilai PM2.5 riil di database
function dynamicAiStatus(pm25: number, currentStatus: string | null): string {
  if (pm25 >= 190) return '🚨 Kebakaran Besar';
  if (pm25 > 50) return '⚠️ Asap Tebal - Waspada';
  return currentStatus || '✅ Normal Bersih';
}

function dynamicKatAsap(pm25: number, currentKat: string | null): string {
  if (pm25 >= 190) return 'Kebakaran Besar';
  if (pm25 > 50) return 'Polusi Udara / Debu / Asap Lokal';
  return currentKat || 'Udara Bersih';
}

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const nodeCode = searchParams.get('nodeCode');
    const limit = Math.min(parseInt(searchParams.get('limit') || '20', 10) || 20, 200);

    // KONDISI A: JIKA MENERIMA QUERY PARAMETER NODE CODE (UNTUK GRAFIK / TABEL LOGS)
    if (nodeCode) {
      const node = await prisma.deviceNode.findUnique({ where: { nodeCode } });
      if (!node) return mobileFail('Node tidak ditemukan', 404);

      const readings = await prisma.sensorReading.findMany({
        where: { nodeId: node.id },
        orderBy: { recordedAt: 'desc' },
        take: limit,
      });

      const mappedReadings = readings.map((r: any) => {
        const fixedPm25 = Number(r.pm25 ?? 0);
        return {
          id: r.id,
          nodeCode: node.nodeCode,
          node_name: node.name || node.nodeCode,
          pm1: Number(r.pm1 ?? 0),
          pm25: fixedPm25,
          pm10: Number(r.pm10 ?? 0),
          suhu: Number(r.temperature ?? r.suhu ?? 0),
          temperature: Number(r.temperature ?? r.suhu ?? 0),
          kelembapan: Number(r.humidity ?? r.kelembapan ?? 0),
          humidity: Number(r.humidity ?? r.kelembapan ?? 0),
          aiStatusResult: dynamicAiStatus(fixedPm25, r.aiStatusResult ?? r.statusTerpadu ?? r.status),
          kat_asap: dynamicKatAsap(fixedPm25, r.kat_asap ?? r.kategoriAsap ?? r.kategori_asap),
          recordedAt: r.recordedAt,
        };
      });

      return mobileOk(mappedReadings, 'Riwayat partikulat node berhasil diambil', 200);
    }

    // KONDISI B: JIKA TANPA QUERY PARAMETER (UNTUK RINGKASAN DATA TERBARU DASHBOARD UTAMA DARI SEMUA NODE)
    const nodes = await prisma.deviceNode.findMany({
      include: {
        sensorReadings: {
          orderBy: { recordedAt: 'desc' },
          take: 1,
        },
      },
      orderBy: { nodeCode: 'asc' },
    });

    const activeMonitoringData = nodes.map((n: any) => {
      const latest = n.sensorReadings[0] || {};
      const fixedPm25 = Number(latest.pm25 ?? 0);
      return {
        id: n.id,
        nodeCode: n.nodeCode,
        node_name: n.name || n.nodeCode,
        pm1: Number(latest.pm1 ?? 0),
        pm25: fixedPm25,
        pm10: Number(latest.pm10 ?? 0),
        suhu: Number(latest.temperature ?? latest.suhu ?? 0),
        temperature: Number(latest.temperature ?? latest.suhu ?? 0),
        kelembapan: Number(latest.humidity ?? latest.kelembapan ?? 0),
        humidity: Number(latest.humidity ?? latest.kelembapan ?? 0),
        aiStatusResult: dynamicAiStatus(fixedPm25, latest.aiStatusResult ?? latest.statusTerpadu ?? latest.status),
        kat_asap: dynamicKatAsap(fixedPm25, latest.kat_asap ?? latest.kategoriAsap ?? latest.kategori_asap),
        recordedAt: latest.recordedAt || new Date().toISOString(),
      };
    });

    return mobileOk(activeMonitoringData, 'Data live monitoring partikulat berhasil diambil', 200);
  } catch (error: any) {
    console.error('❌ [MOBILE][live-monitoring-partikulat] Error:', error);
    return mobileFail(error.message || 'Terjadi kesalahan pada server', 500);
  }
}