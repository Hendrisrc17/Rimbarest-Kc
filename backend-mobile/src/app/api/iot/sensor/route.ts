// File: src/app/api/iot/sensor/route.ts
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendPushNotification } from '@/services/notification';
import { createNotification } from '@/lib/mobile-notify';
import { revalidatePath } from 'next/cache';

export const maxDuration = 300;
export const dynamic = 'force-dynamic';

const LABEL_ANCAMAN_BINARY = 'Ancaman Terdeteksi';
const DAFTAR_ANCAMAN_LEGACY = ['Chainsaw', 'Axe', 'Handsaw', 'Engine', 'WoodChp', 'Gen', 'Gunshot', 'TreeFall'];

function isLabelAncaman(label: string): boolean {
  if (!label) return false;
  const normalized = label.trim().toLowerCase();
  if (normalized === LABEL_ANCAMAN_BINARY.toLowerCase() || normalized === 'positif') return true;
  return DAFTAR_ANCAMAN_LEGACY.some((threat) => normalized.includes(threat.toLowerCase()));
}

function aiBaseUrl(): string {
  let url = (process.env.AI_SERVER_URL || 'http://localhost:8000').trim();
  url = url.replace(/\/+$/, '');
  url = url.replace(/\/(predict-iot|predict|evaluate-condition)$/i, '');
  return url;
}

function withTimeoutSignal(ms: number): AbortSignal {
  return AbortSignal.timeout(ms);
}

function parsePercentToFraction(value: unknown, fallback: number): number {
  if (value === undefined || value === null || value === '') return fallback;
  const num = Number(String(value).replace('%', '').trim());
  return Number.isFinite(num) ? num / 100 : fallback;
}

function parseRemainingMb(raw: unknown): number | null {
  if (raw === undefined || raw === null || raw === '') return null;
  const num = Number(raw);
  if (!Number.isFinite(num) || num < 0) return null;
  return num;
}

// 🧠 HELPER DENGAN PENANGANAN NULL/INVALID LAT & LNG SENSOR RIIL
function parseCoordinate(val: any): number | null {
  if (val === undefined || val === null || val === '') return null;
  const num = Number(val);
  if (!Number.isFinite(num) || num === 0) return null;
  return num;
}

const QUOTA_WARNING_THRESHOLD_MB = 1000;
const QUOTA_CRITICAL_THRESHOLD_MB = 100;

type QuotaTier = 'CRITICAL' | 'WARNING' | 'NORMAL';

function getQuotaTier(remainingMb: number): QuotaTier {
  if (remainingMb <= QUOTA_CRITICAL_THRESHOLD_MB) return 'CRITICAL';
  if (remainingMb <= QUOTA_WARNING_THRESHOLD_MB) return 'WARNING';
  return 'NORMAL';
}

async function sendQuotaTierNotification(tier: 'CRITICAL' | 'WARNING', nodeCode: string, remainingMb: number, deviceNodeId: string) {
  const titlePrefix = tier === 'CRITICAL' ? '🚨 KUOTA INTERNET KRITIS' : '⚠️ KUOTA INTERNET HAMPIR HABIS';

  const existingNotification = await prisma.notification.findFirst({
    where: {
      nodeId: deviceNodeId,
      title: { startsWith: titlePrefix },
      createdAt: {
        gte: new Date(new Date().setHours(0, 0, 0, 0))
      }
    }
  });

  if (existingNotification) {
    console.log(`[FCM Quota Skip] Notifikasi ${tier} untuk ${nodeCode} sudah dikirim hari ini.`);
    return;
  }

  const activeTokens = await prisma.deviceToken.findMany({
    where: { isActive: true },
    select: { token: true }
  });

  const pushTitle = tier === 'CRITICAL'
    ? '🚨 PERINGATAN: KUOTA INTERNET IOT SEGERA HABIS'
    : '⚠️ Kuota Internet IoT Mulai Menipis';

  const pushBody = tier === 'CRITICAL'
    ? `Sisa kuota data internet pada ${nodeCode} tinggal ${remainingMb} MB! Segera isi ulang.`
    : `Sisa kuota data internet pada ${nodeCode} tinggal ${remainingMb} MB (di bawah 1 GB).`;

  if (activeTokens.length > 0) {
    await sendPushNotification(pushTitle, pushBody).catch((err) => console.error('[Notif Kuota] Gagal kirim:', err));
  }

  const adminUser = await prisma.user.findFirst({ where: { role: 'ADMIN' } });

  await prisma.notification.create({
    data: {
      nodeId: deviceNodeId,
      userId: adminUser?.id || null,
      title: `${titlePrefix}: ${nodeCode}`,
      message: pushBody,
      type: tier === 'CRITICAL' ? 'WARNING' : 'INFO',
      metadata: { remainingMb, tier }
    }
  });
}

async function checkAndTriggerQuotaNotification(nodeCode: string, quotaAlertField: any, remainingMbField: any, deviceNodeId: string) {
  const remainingMb = parseRemainingMb(remainingMbField);

  if (remainingMb !== null) {
    await prisma.deviceNode.update({
      where: { id: deviceNodeId },
      data: { quotaInternet: remainingMb },
    }).catch((err) => console.error('[Quota Persist] Gagal update quotaInternet:', err));
  }

  if (remainingMb === null) return;

  const tier = getQuotaTier(remainingMb);
  if (tier === 'NORMAL') return;

  await sendQuotaTierNotification(tier, nodeCode, remainingMb, deviceNodeId);
}

export async function POST(request: Request) {
  try {
    const contentType = request.headers.get('content-type') || '';

    if (contentType.includes('multipart/form-data')) {
      return await handleDeviceUpload(request);
    }

    if (contentType.includes('application/json')) {
      const body = await request.json();

      const isAiCallback = Boolean(
        body.aiLabelDetected ||
        body.aiAudioPredictionScore ||
        body.aiAudioScore ||
        body.aiPartikulatPredictionScore ||
        body.aiPartikulatScore ||
        body.aiStatusResult ||
        body.aiProbabilities ||
        body.readingId
      );

      if (isAiCallback) {
        return await handleAiCallback(body);
      }
      return await handleSensorOnly(body);
    }

    return NextResponse.json({ success: false, error: 'Unsupported content-type' }, { status: 415 });
  } catch (error: any) {
    console.error('❌ [IOT] Gagal memproses request:', error);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

async function handleDeviceUpload(request: Request) {
  const formData = await request.formData();

  const pm1 = Number(formData.get('pm1') || 0);
  const pm25 = Number(formData.get('pm25') || 0);
  const pm10 = Number(formData.get('pm10') || 0);
  
  const suhu = Number(formData.get('suhu') || formData.get('temperature') || 0);
  const kelembapan = Number(formData.get('kelembapan') || formData.get('humidity') || 0);
  
  const noiseLevel = Number(formData.get('noiseLevel') || 52.0);
  const nodeCode = (formData.get('nodeCode') as string) || 'NODE-001';
  const cacheSource = formData.get('cacheSource') === 'true';
  const quotaAlert = formData.get('quotaAlert');
  const remainingMb = formData.get('remainingMb');

  // 📍 TANGKAP KOORDINAT LATITUDE & LONGITUDE DARI FORM-DATA
  const lat = parseCoordinate(formData.get('latitude') || formData.get('lat'));
  const lng = parseCoordinate(formData.get('longitude') || formData.get('lng') || formData.get('lon'));

  let deviceNode = await prisma.deviceNode.findUnique({ where: { nodeCode } });
  if (!deviceNode) {
    deviceNode = await prisma.deviceNode.create({
      data: {
        nodeCode,
        name: `Node ${nodeCode}`,
        status: 'ONLINE',
        latitude: lat,
        longitude: lng,
      }
    });
  } else {
    // 🔥 PERBAIKAN: SINKRONKAN LAT/LNG TERBARU KE TABEL DEVICENODE
    await prisma.deviceNode.update({
      where: { id: deviceNode.id },
      data: {
        status: 'ONLINE',
        lastSeen: new Date(),
        ...(lat !== null ? { latitude: lat } : {}),
        ...(lng !== null ? { longitude: lng } : {}),
      },
    });
  }

  try {
    await checkAndTriggerQuotaNotification(nodeCode, quotaAlert, remainingMb, deviceNode.id);
  } catch (quotaErr) {
    console.error('⚠️ [QUOTA ERROR]:', quotaErr);
  }

  const initialPayload = {
    pm1, pm25, pm10, suhu, kelembapan, noiseLevel, nodeCode,
    latitude: lat ?? deviceNode.latitude,
    longitude: lng ?? deviceNode.longitude,
    aiDetectedAudioLabel: 'Menganalisis Audio...',
    aiLabelDetected: 'Menganalisis Audio...',
    aiStatusResult: '🔄 Menganalisis AI',
    aiKategoriAsap: pm25 >= 190 ? 'Asap Tebal' : 'Udara Bersih',
    kat_asap: pm25 >= 190 ? 'Asap Tebal' : 'Udara Bersih',
    quotaAlert,
    remainingMb
  };

  const newReading = await prisma.sensorReading.create({
    data: {
      nodeId: deviceNode.id,
      pm1,
      pm25,
      pm10,
      temperature: suhu,
      humidity: kelembapan,
      noiseLevel,
      latitude: lat ?? deviceNode.latitude,
      longitude: lng ?? deviceNode.longitude,
      statusTerpadu: '🔄 Menganalisis AI',
      cacheSource,
      rawPayload: JSON.stringify(initialPayload),
      recordedAt: new Date(),
    }
  });

  let audioBuffer: Buffer | null = null;
  const fileField = formData.get('file') || formData.get('audio') || formData.get('wav');
  if (fileField && typeof (fileField as any).arrayBuffer === 'function') {
    const ab = await (fileField as any).arrayBuffer();
    audioBuffer = Buffer.from(ab);
  }

  if (!audioBuffer || audioBuffer.length < 100) {
    return await handleSensorOnly(
      { pm1, pm25, pm10, suhu, kelembapan, noiseLevel, nodeCode, cacheSource, quotaAlert, remainingMb, latitude: lat, longitude: lng },
      deviceNode,
      true
    );
  }

  const finalWavBuffer = audioBuffer;
  const audioUrl = await persistAudioTemporarily(finalWavBuffer, nodeCode);

  const predictFormData = new FormData();
  const audioBlob = new Blob([new Uint8Array(finalWavBuffer)], { type: 'audio/wav' });
  predictFormData.append('file', audioBlob, `${nodeCode}_stream.wav`);
  
  predictFormData.append('pm1', String(pm1));
  predictFormData.append('pm25', String(pm25));
  predictFormData.append('pm10', String(pm10));
  predictFormData.append('suhu', String(suhu));
  predictFormData.append('kelembapan', String(kelembapan));
  predictFormData.append('noiseLevel', String(noiseLevel));
  predictFormData.append('nodeCode', nodeCode);
  if (lat !== null) predictFormData.append('latitude', String(lat));
  if (lng !== null) predictFormData.append('longitude', String(lng));
  predictFormData.append('cacheSource', String(cacheSource));
  predictFormData.append('readingId', newReading.id);
  if (quotaAlert) predictFormData.append('quotaAlert', String(quotaAlert));
  if (remainingMb) predictFormData.append('remainingMb', String(remainingMb));
  if (audioUrl) predictFormData.append('audioUrl', audioUrl);

  fetch(`${aiBaseUrl()}/predict-iot`, {
    method: 'POST',
    body: predictFormData,
  }).catch((err) => console.error('⚠️ [AI Gateway Error]:', err.message));

  return NextResponse.json({ 
    success: true, 
    status: 'accepted', 
    processing: true, 
    readingId: newReading.id,
    audioUrl 
  }, { status: 202 });
}

async function handleSensorOnly(
  data: {
    pm1: number;
    pm25: number;
    pm10: number;
    suhu: number;
    kelembapan: number;
    noiseLevel: number;
    nodeCode: string;
    cacheSource: boolean;
    latitude?: any;
    longitude?: any;
    quotaAlert?: any;
    remainingMb?: any;
  },
  preloadedNode?: { id: string; nodeCode: string; latitude?: any; longitude?: any } | null,
  isQuotaAlreadyChecked: boolean = false
) {
  const pm1 = Number(data.pm1 ?? 0);
  const pm25 = Number(data.pm25 ?? 0);
  const pm10 = Number(data.pm10 ?? 0);
  const suhu = Number(data.suhu ?? (data as any).temperature ?? 0);
  const kelembapan = Number(data.kelembapan ?? (data as any).humidity ?? 0);
  const noiseLevel = Number(data.noiseLevel ?? 52.0);
  const nodeCode = data.nodeCode || 'NODE-001';
  const cacheSource = Boolean(data.cacheSource);

  // 📍 TANGKAP KOORDINAT LATITUDE & LONGITUDE
  const lat = parseCoordinate(data.latitude ?? (data as any).lat);
  const lng = parseCoordinate(data.longitude ?? (data as any).lng ?? (data as any).lon);

  let deviceNode = preloadedNode ?? (await prisma.deviceNode.findUnique({ where: { nodeCode } }));
  if (!deviceNode) {
    deviceNode = await prisma.deviceNode.create({
      data: {
        nodeCode,
        name: `Node ${nodeCode}`,
        status: 'ONLINE',
        latitude: lat,
        longitude: lng,
      }
    });
  }

  const audioLabel = noiseLevel <= 54.0 ? 'Silence' : 'Normal Ambient';

  if (!isQuotaAlreadyChecked) {
    try {
      await checkAndTriggerQuotaNotification(nodeCode, data.quotaAlert, data.remainingMb, deviceNode.id);
    } catch (quotaErr) {
      console.error('⚠️ [QUOTA ALERT ERROR]:', quotaErr);
    }
  }

  let statusTerpadu = '✅ Normal Bersih';
  let kategoriAsap = 'Udara Bersih';
  let isAnomaly = false;
  let partikulatScore = 0.94;

  try {
    const evalForm = new FormData();
    evalForm.append('pm1', String(pm1));
    evalForm.append('pm25', String(pm25));
    evalForm.append('pm10', String(pm10));
    evalForm.append('suhu', String(suhu));
    evalForm.append('kelembapan', String(kelembapan));
    evalForm.append('label_audio_ai', audioLabel);

    const evalResponse = await fetch(`${aiBaseUrl()}/evaluate-condition`, {
      method: 'POST',
      body: evalForm,
      signal: withTimeoutSignal(6000),
    });
    if (evalResponse.ok) {
      const evalResult = await evalResponse.json();
      statusTerpadu = evalResult.status ?? statusTerpadu;
      kategoriAsap = Array.isArray(evalResult.kategoriAsap)
        ? evalResult.kategoriAsap[0]
        : (evalResult.kategoriAsap ?? kategoriAsap);
      isAnomaly = evalResult.isAnomaly ?? isAnomaly;
      partikulatScore = evalResult.isolationForestScore ?? partikulatScore;
    }
  } catch (err: any) {
    console.error('❌ [AI] FastAPI Server unreachable for condition assessment:', err.message);
  }

  const enrichedPayload = {
    pm1, pm25, pm10, suhu, kelembapan, noiseLevel, nodeCode,
    latitude: lat ?? deviceNode.latitude,
    longitude: lng ?? deviceNode.longitude,
    aiDetectedAudioLabel: audioLabel,
    aiLabelDetected: audioLabel,
    aiPartikulatPredictionScore: `${(partikulatScore * 100).toFixed(2)}%`,
    aiStatusResult: statusTerpadu,
    aiKategoriAsap: kategoriAsap,
    kat_asap: kategoriAsap,
    quotaAlert: data.quotaAlert,
    remainingMb: data.remainingMb
  };

  const newReading = await prisma.sensorReading.create({
    data: {
      nodeId: deviceNode.id,
      pm1,
      pm25,
      pm10,
      temperature: suhu,
      humidity: kelembapan,
      noiseLevel,
      latitude: lat ?? deviceNode.latitude,
      longitude: lng ?? deviceNode.longitude,
      statusTerpadu,
      cacheSource,
      rawPayload: JSON.stringify(enrichedPayload),
      recordedAt: new Date(),
    },
  });

  // 🔥 UPDATE DEVICENODE KOORDINAT & LASTSEEN
  await prisma.deviceNode.update({
    where: { id: deviceNode.id },
    data: {
      status: 'ONLINE',
      lastSeen: new Date(),
      ...(lat !== null ? { latitude: lat } : {}),
      ...(lng !== null ? { longitude: lng } : {}),
    },
  });

  const isPartikulatThreat = pm25 > 150 || statusTerpadu.toLowerCase().includes('asap') || statusTerpadu.toLowerCase().includes('bahaya');
  if (isPartikulatThreat) {
    const activeTokens = await prisma.deviceToken.findMany({
      where: { isActive: true },
      select: { token: true }
    });

    if (activeTokens.length > 0) {
      await sendPushNotification(
        `🚨 BAHAYA ASAP: ${kategoriAsap.toUpperCase()}!`,
        `Kadar PM2.5 terdeteksi sangat tinggi (${pm25} µg/m³) di node ${nodeCode}. Potensi Kebakaran Hutan!`,
      ).catch((err) => console.error('[Notif] Gagal kirim:', err));
    }

    const adminUser = await prisma.user.findFirst({ where: { role: 'ADMIN' } });
    
    createNotification({
      nodeId: deviceNode.id,
      userId: adminUser?.id || null,
      title: `🔥 ANOMALI PARTIKULAT: ${kategoriAsap.toUpperCase()}`,
      message: `Konsentrasi PM2.5 tinggi mencapai ${pm25} µg/m³ di kawasan perlindungan ${nodeCode}.`,
      type: 'DANGER',
    });
  }

  revalidatePath('/api/mobile/dashboard');

  return NextResponse.json(
    { success: true, readingId: newReading.id, aiStatusResult: statusTerpadu, isAnomaly },
    { status: 201 },
  );
}

async function handleAiCallback(body: any) {
  const readingId = body.readingId;
  const nodeCode = body.nodeCode || 'NODE-001';
  const pm1 = Number(body.pm1 ?? 0);
  const pm25 = Number(body.pm25 ?? 0);
  const pm10 = Number(body.pm10 ?? 0);
  
  const suhu = Number(body.suhu ?? body.temperature ?? 0);
  const kelembapan = Number(body.kelembapan ?? body.humidity ?? 0);
  
  const noiseLevel = Number(body.noiseLevel ?? 52.0);
  const cacheSource = Boolean(body.cacheSource);
  const quotaAlert = body.quotaAlert;
  const remainingMb = body.remainingMb;

  // 📍 TANGKAP KOORDINAT LATITUDE & LONGITUDE DARI CALLBACK
  const lat = parseCoordinate(body.latitude ?? body.lat);
  const lng = parseCoordinate(body.longitude ?? body.lng ?? body.lon);

  let deviceNode = await prisma.deviceNode.findUnique({ where: { nodeCode } });
  if (!deviceNode) {
    deviceNode = await prisma.deviceNode.create({
      data: {
        nodeCode,
        name: `Node ${nodeCode}`,
        status: 'ONLINE',
        latitude: lat,
        longitude: lng,
      }
    });
  }

  try {
    await checkAndTriggerQuotaNotification(nodeCode, quotaAlert, remainingMb, deviceNode.id);
  } catch (quotaErr) {
    console.error('⚠️ [QUOTA ALERT ERROR]:', quotaErr);
  }

  const finalAudioLabel: string = body.aiLabelDetected || 'Silence';
  const calculatedAudioScore = parsePercentToFraction(body.aiAudioPredictionScore ?? body.aiAudioScore, 0.95);
  const calculatedPartikulatScore = parsePercentToFraction(body.aiPartikulatPredictionScore ?? body.aiPartikulatScore, 0.94);
  const statusFinalTerpadu: string = body.aiStatusResult || '✅ Normal Bersih';
  const kategoriAsap: string = body.kat_asap || body.kategoriAsap || 'Udara Bersih';
  const aiRawSigmoidScore = body.aiRawSigmoidScore ?? null;
  const aiProbabilities = body.aiProbabilities ?? null;
  const audioUrl: string | null = body.audioUrl || null;

  const isAudioThreat = isLabelAncaman(finalAudioLabel);
  const isPartikulatThreat = pm25 > 150 || statusFinalTerpadu.toLowerCase().includes('asap') || statusFinalTerpadu.toLowerCase().includes('kebakaran');

  const enrichedPayload = {
    pm1, pm25, pm10, suhu, kelembapan, noiseLevel, nodeCode,
    latitude: lat ?? deviceNode.latitude,
    longitude: lng ?? deviceNode.longitude,
    aiDetectedAudioLabel: finalAudioLabel,
    aiLabelDetected: finalAudioLabel,
    aiAudioPredictionScore: `${(calculatedAudioScore * 100).toFixed(2)}%`,
    aiPartikulatPredictionScore: `${(calculatedPartikulatScore * 100).toFixed(2)}%`,
    aiStatusResult: statusFinalTerpadu,
    aiKategoriAsap: kategoriAsap,
    kat_asap: kategoriAsap,
    aiRawSigmoidScore,
    aiProbabilities,
  };

  let activeReadingRecord;
  if (readingId) {
    activeReadingRecord = await prisma.sensorReading.update({
      where: { id: readingId },
      data: {
        statusTerpadu: statusFinalTerpadu,
        latitude: lat ?? deviceNode.latitude,
        longitude: lng ?? deviceNode.longitude,
        rawPayload: JSON.stringify(enrichedPayload),
      }
    }).catch(() => null);
  }

  if (!activeReadingRecord) {
    activeReadingRecord = await prisma.sensorReading.create({
      data: {
        nodeId: deviceNode.id,
        pm1,
        pm25,
        pm10,
        temperature: suhu,
        humidity: kelembapan,
        noiseLevel,
        latitude: lat ?? deviceNode.latitude,
        longitude: lng ?? deviceNode.longitude,
        statusTerpadu: statusFinalTerpadu,
        cacheSource,
        rawPayload: JSON.stringify(enrichedPayload),
        recordedAt: new Date(),
      },
    });
  }

  const activeTokens = await prisma.deviceToken.findMany({
    where: { isActive: true },
    select: { token: true }
  });

  const hasActiveDevices = activeTokens.length > 0;

  if (isAudioThreat) {
    await prisma.audioIncident.create({
      data: {
        nodeId: deviceNode.id,
        sensorReadingId: activeReadingRecord.id,
        audioUrl: audioUrl || 'AUDIO_URL_TIDAK_TERSEDIA.WAV',
        predictionScore: calculatedAudioScore,
        label: finalAudioLabel,
        createdAt: new Date(),
      },
    });

    if (hasActiveDevices) {
      await sendPushNotification(
        `🚨 BAHAYA UTAMA: ${finalAudioLabel.toUpperCase()}!`,
        `Model AI mendeteksi indikasi kuat adanya aktivitas mencurigakan (${finalAudioLabel}) di node ${nodeCode} (Confidence: ${(calculatedAudioScore * 100).toFixed(1)}%). Segera cek lokasi!`,
      ).catch((err: any) => console.error('[Notif] Gagal kirim notifikasi:', err));
    }

    const firstActiveUser = await prisma.user.findFirst({ where: { role: 'ADMIN' } });
    
    createNotification({
      nodeId: deviceNode.id,
      userId: firstActiveUser?.id || null,
      title: `🚨 BAHAYA: ${finalAudioLabel.toUpperCase()}`,
      message: `Terdeteksi ${finalAudioLabel} di node ${nodeCode} (Confidence: ${(calculatedAudioScore * 100).toFixed(1)}%).`,
      type: 'DANGER',
    });
  }

  if (isPartikulatThreat && !isAudioThreat) {
    if (hasActiveDevices) {
      await sendPushNotification(
        `🔥 AWAS ASAP: ASAP TEBAL TERDETEKSI!`,
        `Kadar emisi PM2.5 meningkat tajam (${pm25} µg/m³) di sektor node ${nodeCode}. Waspada potensi kebakaran semak/hutan!`,
      ).catch((err: any) => console.error('[Notif] Gagal kirim notifikasi partikulat:', err));
    }

    const firstActiveUser = await prisma.user.findFirst({ where: { role: 'ADMIN' } });
    
    createNotification({
      nodeId: deviceNode.id,
      userId: firstActiveUser?.id || null,
      title: `🔥 ASAP: ASAP TEBAL`,
      message: `Konsentrasi partikulat udara PM2.5 melonjak tinggi sebesar ${pm25} µg/m³ di node ${nodeCode}.`,
      type: 'DANGER',
    });
  }

  // 🔥 UPDATE DEVICENODE KOORDINAT TERKINI
  await prisma.deviceNode.update({
    where: { id: deviceNode.id },
    data: {
      status: 'ONLINE',
      lastSeen: new Date(),
      ...(lat !== null ? { latitude: lat } : {}),
      ...(lng !== null ? { longitude: lng } : {}),
    },
  });

  revalidatePath('/api/mobile/dashboard');

  return NextResponse.json(
    {
      success: true,
      readingId: activeReadingRecord.id,
      aiLabelDetected: finalAudioLabel,
      aiStatusResult: statusFinalTerpadu,
      isAudioThreat,
    },
    { status: 200 },
  );
}

async function persistAudioTemporarily(wavBuffer: Buffer, nodeCode: string): Promise<string | null> {
  return `local://${nodeCode}_${Date.now()}.wav`;
}