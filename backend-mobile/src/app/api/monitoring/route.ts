// D:\dataleptop\Downloads\PKM_KC\backend-mobile\src\app\api\monitoring\route.ts
import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * 1. METHOD GET: Untuk menyuplai data ke Dashboard Frontend (page.tsx)
 * Menghilangkan Eror 405 Method Not Allowed
 */
export async function GET() {
  try {
    // Ambil 10 data log sensor terbaru untuk disuplai ke tabel dashboard
    const readings = await prisma.sensorReading.findMany({
      take: 10,
      orderBy: {
        recordedAt: 'desc',
      },
      include: {
        node: true, // Menyertakan relasi status DeviceNode
      },
    });

    // Ambil status seluruh node alat aktif
    const nodes = await prisma.deviceNode.findMany({
      orderBy: {
        nodeCode: 'asc',
      },
    });

    return NextResponse.json({ 
      success: true, 
      readings: readings || [], 
      nodes: nodes || [] 
    });
  } catch (error: any) {
    console.error("❌ Gagal mengambil data untuk dashboard:", error);
    return NextResponse.json(
      { success: false, error: error.message }, 
      { status: 500 }
    );
  }
}

/**
 * 2. METHOD POST: Untuk menerima data IoT masuk dari ESP32 / Hardware
 */
export async function POST(request: Request) {
  try {
    const body = await request.json();
    console.log("[IOT] Request masuk dari perangkat.");

    // Amankan pemetaan nama sensor fleksibel ganda agar suhu tidak bernilai 0
    const pm1 = body.pm1 !== undefined ? body.pm1 : 0;
    const pm25 = body.pm25 !== undefined ? body.pm25 : 0;
    const pm10 = body.pm10 !== undefined ? body.pm10 : 0;
    
    const suhu = body.suhu !== undefined 
      ? body.suhu 
      : (body.temperature !== undefined ? body.temperature : 0);
      
    const kelembapan = body.kelembapan !== undefined 
      ? body.kelembapan 
      : (body.humidity !== undefined ? body.humidity : 0);
      
    const noiseLevel = body.noiseLevel !== undefined ? body.noiseLevel : 45.0;
    const nodeCode = body.nodeCode || 'NODE-001';
    const audioBase64 = body.audioBase64;

    // A. Cari kecocokan registrasi ID Node berdasarkan data nodeCode
    const deviceNode = await prisma.deviceNode.findUnique({
      where: { nodeCode: nodeCode },
    });

    if (!deviceNode) {
      return NextResponse.json({ success: false, error: 'Node tidak terdaftar.' }, { status: 404 });
    }

    // B. Lempar data secara otomatis ke FastAPI Python AI Server
    const formData = new FormData();
    formData.append('pm1', String(pm1));
    formData.append('pm25', String(pm25));
    formData.append('pm10', String(pm10));
    formData.append('suhu', String(suhu));
    formData.append('kelembapan', String(kelembapan));
    formData.append('label_audio_ai', 'Silence');

    if (audioBase64) {
      const audioBuffer = Buffer.from(audioBase64, 'base64');
      const safeUint8Array = new Uint8Array(
        audioBuffer.buffer,
        audioBuffer.byteOffset,
        audioBuffer.byteLength
      );
      const audioBlob = new Blob([safeUint8Array], { type: 'audio/wav' });
      formData.append('file', audioBlob, 'hardware_live.wav');
    }

    let aiResult = {
      status: "🔍 Anomali Alat/Cuaca",
      audioLabel: "Silence"
    };

    try {
      const pythonAiResponse = await fetch('http://127.0.0.1:8000/evaluate-condition', {
        method: 'POST',
        body: formData,
      });
      if (pythonAiResponse.ok) {
        const dataRes = await pythonAiResponse.json();
        aiResult.status = dataRes.status;
        aiResult.audioLabel = dataRes.audioLabel;
        console.log(`====================================================================`);
        console.log(`[POSTGRE - REALTIME SUCCESS] 🚀 1 Data Realtime Masuk PostgreSQL!`);
        console.log(`Node: ${nodeCode} | Status Murni Python: ${aiResult.status}`);
        console.log(`====================================================================`);
      }
    } catch (aiErr) {
      console.error("⚠️ Koneksi FastAPI Gagal, Menggunakan Fallback Logika Lokal.");
    }

    // Satukan label deteksi AI ke dalam payload terstruktur
    const enrichedPayload = {
      ...body,
      aiDetectedAudioLabel: aiResult.audioLabel,
      aiStatusResult: aiResult.status
    };

    // C. Simpan data realtime ke database PostgreSQL lewat Prisma
    // 🔥 FIX PRISMA CLIENT VALIDATION ERROR: Kolom 'audioLabel' dibersihkan dari skema tulis objek
    const newReading = await prisma.sensorReading.create({
      data: {
        nodeId: deviceNode.id,
        pm1: Number(pm1),
        pm25: Number(pm25),
        pm10: Number(pm10),
        temperature: Number(suhu),
        humidity: Number(kelembapan),
        noiseLevel: Number(noiseLevel),
        statusTerpadu: aiResult.status,
        cacheSource: false,
        rawPayload: JSON.stringify(enrichedPayload), // Hasil deteksi 'Insect'/'Chainsaw' aman di dalam json text ini
        recordedAt: new Date(),
      },
    });

    // D. Update metadata status keaktifan node hardware
    await prisma.deviceNode.update({
      where: { id: deviceNode.id },
      data: {
        status: 'ONLINE',
        lastSeen: new Date(),
        latitude: body.latitude ? Number(body.latitude) : deviceNode.latitude,
        longitude: body.longitude ? Number(body.longitude) : deviceNode.longitude,
      },
    });

    return NextResponse.json({ success: true, readingId: newReading.id }, { status: 201 });

  } catch (error: any) {
    console.error("❌ Gagal memproses data IoT masuk:", error);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}