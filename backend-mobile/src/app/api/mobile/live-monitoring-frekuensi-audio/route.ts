// File: src/app/api/mobile/live-monitoring-frekuensi-audio/route.ts
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const nodeCode = searchParams.get('nodeCode') || searchParams.get('node') || '';

    // Filter Node jika ada parameter nodeCode
    let nodeWhereClause = {};
    if (nodeCode) {
      const targetNode = await prisma.deviceNode.findUnique({ where: { nodeCode } });
      if (targetNode) {
        nodeWhereClause = { nodeId: targetNode.id };
      }
    }

    // 1. TAMBAHKAN RIWAYAT UTAMA DARI TABEL AudioIncident (Dibatasi 3 saja)
    const incidents = await prisma.audioIncident.findMany({
      where: nodeWhereClause,
      take: 3,
      orderBy: { createdAt: 'desc' },
      include: {
        node: { select: { nodeCode: true, name: true } },
      },
    });

    // 2. TARIK SENSOR READING SEBAGAI CADANGAN (Dibatasi 3 saja)
    const sensorReadings = await prisma.sensorReading.findMany({
      where: nodeWhereClause,
      take: 3,
      orderBy: { recordedAt: 'desc' },
      include: {
        node: { select: { nodeCode: true, name: true } },
      },
    });

    // 3. GABUNGKAN DAN MAPPING DATA AUDIO SECARA PRESISI
    const formattedEvents: Array<{
      id: string;
      label: string;
      predictionScore: number;
      accuracy: string;
      audioUrl: string;
      createdAt: string;
      nodeCode: string;
      isThreat: boolean;
    }> = [];

    // Prioritaskan memasukkan insiden audio nyata (Ancaman Terdeteksi)
    incidents.forEach((inc) => {
      const score = Number(inc.predictionScore ?? 0.95);
      formattedEvents.push({
        id: inc.id,
        label: inc.label || 'Ancaman Terdeteksi',
        predictionScore: score,
        accuracy: `${(score * 100).toFixed(0)}%`,
        audioUrl: inc.audioUrl || '',
        createdAt: inc.createdAt.toISOString(),
        nodeCode: inc.node?.nodeCode || nodeCode || 'NODE-001',
        isThreat: true,
      });
    });

    // Masukkan data SensorReading jika belum terwakili
    sensorReadings.forEach((sr) => {
      let detectedLabel = 'Normal Ambient';
      let score = 0.85;

      if (sr.rawPayload) {
        try {
          const payload = typeof sr.rawPayload === 'string' ? JSON.parse(sr.rawPayload) : sr.rawPayload;
          if (payload) {
            if (payload.aiDetectedAudioLabel) {
              detectedLabel = payload.aiDetectedAudioLabel;
            } else if (payload.aiLabelDetected) {
              detectedLabel = payload.aiLabelDetected;
            }

            if (payload.aiAudioPredictionScore) {
              const parsedScore = parseFloat(String(payload.aiAudioPredictionScore).replace('%', ''));
              if (!isNaN(parsedScore)) score = parsedScore / 100;
            }
          }
        } catch (e) {
          // Abaikan kesalahan parse JSON
        }
      }

      if (detectedLabel === 'Silence') {
        detectedLabel = 'Normal Ambient';
      }

      const isThreat = detectedLabel.toLowerCase().includes('ancaman') || detectedLabel.toLowerCase().includes('positif');

      const exists = formattedEvents.some(
        (ev) => Math.abs(new Date(ev.createdAt).getTime() - new Date(sr.recordedAt).getTime()) < 2000
      );

      if (!exists) {
        formattedEvents.push({
          id: sr.id,
          label: detectedLabel,
          predictionScore: score,
          accuracy: `${(score * 100).toFixed(0)}%`,
          audioUrl: '',
          createdAt: sr.recordedAt.toISOString(),
          nodeCode: sr.node?.nodeCode || nodeCode || 'NODE-001',
          isThreat,
        });
      }
    });

    // Urutkan berdasarkan tanggal terbaru LALU POTONG HANYA 3 DATA TERATAS
    formattedEvents.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    const finalTop3Events = formattedEvents.slice(0, 3);

    return mobileOk(
      {
        total: finalTop3Events.length,
        events: finalTop3Events,
        data: finalTop3Events,
        latestAudio: finalTop3Events.length > 0 ? finalTop3Events[0] : null,
      },
      'OK',
      200
    );
  } catch (error: any) {
    console.error('❌ [MOBILE AUDIO MONITORING ERROR]:', error);
    return mobileFail(error.message, 500);
  }
}