// File: src/app/api/audio-incidents/upload/route.ts
import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { sendPushNotification } from '@/services/notification';
import { createNotification } from '@/lib/mobile-notify';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { nodeCode, sensorReadingId, audioUrl, predictionScore, label } = body;

    if (!nodeCode || !sensorReadingId || !audioUrl || !label) {
      return NextResponse.json({ error: 'Parameter input kurang lengkap' }, { status: 400 });
    }

    const node = await prisma.deviceNode.findUnique({ where: { nodeCode } });
    if (!node) {
      return NextResponse.json({ error: 'Node tidak dikenali' }, { status: 404 });
    }

    // 🚀 FIX DATA TYPE: Konversi skor menjadi tipe data Float angka di awal agar kebal error NaN
    const parsedScore = parseFloat(predictionScore?.toString() || '0.0');

    // Simpan data insiden suara anomali terklasifikasi ke basis data
    const incident = await prisma.audioIncident.create({
      data: {
        nodeId: node.id,
        sensorReadingId,
        audioUrl,
        predictionScore: parsedScore,
        label
      }
    });

    // Update status sensorReading terkait menjadi Critical Hazard terverifikasi AI
    await prisma.sensorReading.update({
      where: { id: sensorReadingId },
      data: { statusTerpadu: `🚨 CRITICAL: ${label.toUpperCase()}` }
    });

    // Ambil user ADMIN pertama jika helper createNotification lu membutuhkan relasi userId di database
    const adminUser = await prisma.user.findFirst({ where: { role: 'ADMIN' } });

    // Kirim notifikasi darurat instan dengan prioritas tinggi ke seluruh petugas mobile
    await sendPushNotification(
      `🚨 BAHAYA UTAMA: ${label.toUpperCase()}!`,
      `Model AI mendeteksi indikasi kuat adanya ${label} di ${node.name} (Akurasi: ${(parsedScore * 100).toFixed(1)}%). Segera cek lokasi!`
    ).catch((err) => console.error('⚠️ [FCM] Gagal mengirim push notification:', err));

    // 🌟 Catat juga sebagai notifikasi in-app untuk lonceng notifikasi di aplikasi mobile dengan data relasi aman.
    createNotification({
      nodeId: node.id,
      userId: adminUser?.id || null, // Mencegah crash constraint database
      title: `🚨 BAHAYA: ${label.toUpperCase()}`,
      message: `Terdeteksi ${label} di ${node.name} (Akurasi: ${(parsedScore * 100).toFixed(1)}%).`,
      type: 'DANGER',
    });

    return NextResponse.json({ message: 'Log insiden bahaya AI berhasil diarsip', id: incident.id }, { status: 201 });
  } catch (error: any) {
    console.error('❌ [AUDIO-INCIDENT-UPLOAD] Error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}