// File: src/app/api/mobile/dashboard/route.ts
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getMobileAuthUser } from '@/lib/mobile-auth';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

// 🧠 ENGINE PEMBUAT NARASI AI OTOMATIS (REAL-TIME & SENSITIF ANOMALI)
function generateAiInsightNarrative(
  statusTerpadu: string,
  pm25: number,
  suhu: number,
  kelembapan: number,
  labelAudio: string,
  katAsap: string
): { message: string; tags: string[] } {
  const normAudio = (labelAudio || '').toString().trim().toLowerCase();
  const normStatus = (statusTerpadu || '').toString().trim().toLowerCase();
  const normAsap = (katAsap || '').toString().trim().toLowerCase();

  // 🔥 DETEKSI SANGAT SENSITIF KATA KUNCI ANCAMAN AUDIO
  const isAudioThreat = 
    normAudio.includes('ancaman') || 
    normAudio.includes('positif') || 
    normAudio.includes('chainsaw') || 
    normAudio.includes('gunshot') ||
    normAudio.includes('axe') ||
    normAudio.includes('engine') ||
    normStatus.includes('ancaman');

  // 🔥 DETEKSI SANGAT SENSITIF KATA KUNCI ASAP / KEBAKARAN
  const isSmokeThreat = 
    pm25 >= 190.0 || 
    normAsap.includes('kebakaran') || 
    normAsap.includes('asap') || 
    normStatus.includes('kebakaran') ||
    normStatus.includes('asap');

  const isHighPM = pm25 > 50.0 && pm25 < 190.0;

  const tags: string[] = [];
  let message = '';

  // 🚨 KONDISI 1: ANOMALI GABUNGAN (ASAP/KEBAKARAN + SUARA ANCAMAN)
  if (isSmokeThreat && isAudioThreat) {
    message = `🚨 BAHAYA KRITIS: Model DS-CNN mendeteksi ANCAMAN SUARA (${labelAudio}) berbarengan dengan Indikasi Kebakaran (${katAsap}, PM2.5: ${pm25} µg/m³)! Segera lakukan verifikasi lokasi darurat.`;
    tags.push('KEBAKARAN', 'ANCAMAN AUDIO', 'ANOMALI KRITIS');
  } 
  // ⚠️ KONDISI 2: ANOMALI SUARA TERDETEKSI
  else if (isAudioThreat) {
    message = `⚠️ ANCAMAN SUARA TERDETEKSI: Model Neural Network mencatat indikasi "${labelAudio}" di kawasan node! Parameter partikulat PM2.5 berada di angka ${pm25} µg/m³.`;
    tags.push('ANCAMAN AUDIO', 'ANOMALI SUARA', 'WASPADA');
  } 
  // 🔥 KONDISI 3: ANOMALI ASAP / KEBAKARAN
  else if (isSmokeThreat) {
    message = `🔥 PERINGATAN EMISI: Terdeteksi lonjakan ${katAsap} dengan konsentrasi PM2.5 mencapai ${pm25} µg/m³ pada suhu ${suhu}°C. Waspadai potensi kebakaran semak/hutan.`;
    tags.push('ASAP TEBAL', 'ANOMALI UDARA', 'DANGER');
  } 
  // ⚡ KONDISI 4: POLUSI/DEBU
  else if (isHighPM) {
    message = `⚡ KUALITAS UDARA MENURUN: Terdeteksi akumulasi polusi/debu PM2.5 sebesar ${pm25} µg/m³. Status suara sekitar: ${labelAudio}.`;
    tags.push('POLUSI SEDANG', 'WASPADA');
  } 
  // 💡 KONDISI 5: AMAN & NORMAL
  else {
    message = `✅ KONDISI NORMAL: Parameter lingkungan stabil (PM2.5: ${pm25} µg/m³, Suhu: ${suhu}°C, Humid: ${kelembapan}%). Suara ambient terpantau aman (${labelAudio}).`;
    tags.push('NORMAL', 'LOKAL AMAN');
  }

  return { message, tags };
}

export async function GET(req: NextRequest) {
  try {
    const authUser = getMobileAuthUser(req);

    // 1. Ambil 5 bacaan sensor paling baru
    const allLatestReadings = await prisma.sensorReading.findMany({
      take: 1,
      orderBy: { recordedAt: 'desc' },
      include: { node: { select: { name: true, nodeCode: true, status: true } } },
    });

    const activeReading = allLatestReadings.length > 0 ? allLatestReadings[0] : null;

    const notificationWhereClause = authUser 
      ? { status: 'UNREAD' as const, OR: [{ userId: authUser.id }, { userId: null }] }
      : { status: 'UNREAD' as const, userId: null }; 

    // 2. Query data insiden dan agregasi
    const [totalNodes, onlineNodes, offlineNodes, unreadNotifications, rawIncidents] =
      await Promise.all([
        prisma.deviceNode.count(),
        prisma.deviceNode.count({ where: { status: 'ONLINE' } }),
        prisma.deviceNode.count({ where: { status: 'OFFLINE' } }),
        prisma.notification.count({ where: notificationWhereClause }),
        prisma.audioIncident.findMany({
          take: 3,
          orderBy: { createdAt: 'desc' },
          select: {
            id: true,
            nodeId: true,
            sensorReadingId: true,
            audioUrl: true, 
            predictionScore: true,
            label: true,
            createdAt: true,
            node: { select: { name: true, nodeCode: true } }
          }
        }),
      ]);

    const latestIncidents = rawIncidents.map((inc) => ({
      ...inc,
      label: inc.label || 'Ancaman Terdeteksi',
      accuracy: `${((inc.predictionScore ?? 0.95) * 100).toFixed(0)}%`,
      nodeCode: inc.node?.nodeCode || 'NODE-001',
    }));

    const currentReadings = activeReading ? {
      id: activeReading.id,
      nodeId: activeReading.nodeId,
      pm1: Number(activeReading.pm1 ?? 0),
      pm25: Number(activeReading.pm25 ?? 0),
      pm10: Number(activeReading.pm10 ?? 0),
      temperature: Number(activeReading.temperature ?? 0),
      suhu: Number(activeReading.temperature ?? 0),
      humidity: Number(activeReading.humidity ?? 0),
      kelembapan: Number(activeReading.humidity ?? 0),
      noiseLevel: Number(activeReading.noiseLevel ?? 0),
      statusTerpadu: activeReading.statusTerpadu || '✅ NORMAL BERSIH',
      recordedAt: activeReading.recordedAt,
      node: activeReading.node,
    } : null;

    // 🔍 3. EKSTRAKSI DEEP PAYLOAD AI (SAFE TYPE CASTING)
    let labelAudio = 'Normal Ambient';
    let katAsap = 'Udara Bersih';

    if (activeReading && activeReading.rawPayload) {
      try {
        let payload: any = activeReading.rawPayload;
        
        // Parse bertingkat jika berupa string JSON ganda
        while (typeof payload === 'string') {
          payload = JSON.parse(payload);
        }
          
        if (payload && typeof payload === 'object' && !Array.isArray(payload)) {
          const p = payload as Record<string, any>;
          labelAudio = p.aiDetectedAudioLabel || p.aiLabelDetected || labelAudio;
          katAsap = p.aiKategoriAsap || p.kat_asap || katAsap;
        }
      } catch (e) {
        console.error('⚠️ Gagal parse rawPayload:', e);
      }
    }

    // ⚡ OVERRIDE: JIKA ADA INCIDENT SUARA DALAM 15 MENIT TERAKHIR, PAKSA GUNAKAN LABEL INCIDENT!
    if (latestIncidents.length > 0) {
      const lastInc = latestIncidents[0];
      const incTime = new Date(lastInc.createdAt).getTime();
      const nowTime = new Date().getTime();
      
      if ((nowTime - incTime) < 900000) { // 15 menit
        labelAudio = lastInc.label;
      }
    }

    // 🤖 4. HASILKAN AI INSIGHT DINAMIS
    const smartNarrative = activeReading 
      ? generateAiInsightNarrative(
          activeReading.statusTerpadu || '✅ NORMAL BERSIH',
          Number(activeReading.pm25 ?? 0),
          Number(activeReading.temperature ?? 0),
          Number(activeReading.humidity ?? 0),
          labelAudio,
          katAsap
        )
      : {
          message: 'Sistem mendeteksi kondisi lingkungan dalam batas aman dan normal.',
          tags: ['NORMAL', 'STANDBY']
        };

    const aiInsight = {
      message: smartNarrative.message,
      insightMessage: smartNarrative.message,
      text: smartNarrative.message,
      tags: smartNarrative.tags,
    };

    return mobileOk({
      summary: { totalNodes, onlineNodes, offlineNodes, unreadNotifications },
      currentReadings,
      latestReadings: allLatestReadings,
      latestIncidents,
      aiInsight,
      ...(currentReadings ?? {}),
    }, 'OK', 200);
  } catch (error: any) {
    return mobileFail(error.message, 500);
  }
}