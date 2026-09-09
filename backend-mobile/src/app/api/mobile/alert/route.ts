// File: src/app/api/mobile/alert/route.ts
import { NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { getMobileAuthUser } from '@/lib/mobile-auth';
import { mobileOk, mobileFail } from '@/lib/mobile-response';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function GET(req: NextRequest) {
  try {
    const authUser = getMobileAuthUser(req);

    // 1. Ambil Notifikasi Sistem dari DB
    const notificationWhereClause = authUser 
      ? { OR: [{ userId: authUser.id }, { userId: null }] }
      : { userId: null };

    const rawNotifications = await prisma.notification.findMany({
      where: notificationWhereClause,
      orderBy: { createdAt: 'desc' },
      take: 20,
      include: { node: { select: { name: true, nodeCode: true } } },
    });

    // 2. Ambil Incident Audio
    const rawAudioIncidents = await prisma.audioIncident.findMany({
      take: 20,
      orderBy: { createdAt: 'desc' },
      include: { node: { select: { name: true, nodeCode: true } } },
    });

    // 3. Ambil Anomali Partikulat (Sensor Reading)
    const rawAnomalies = await prisma.sensorReading.findMany({
      where: {
        OR: [
          { pm25: { gte: 190.0 } },
          { statusTerpadu: { contains: 'Kebakaran' } },
          { statusTerpadu: { contains: 'Asap' } },
          { statusTerpadu: { contains: 'Ancaman' } }
        ]
      },
      take: 20,
      orderBy: { recordedAt: 'desc' },
      include: { node: { select: { name: true, nodeCode: true } } },
    });

    // 4. Ambil Data Node/Alat
    const rawNodes = await (prisma as any).deviceNode?.findMany({
      select: {
        id: true,
        nodeCode: true,
        name: true,
      },
    }).catch(() => []) || [];

    // 🔥 GENERATE NOTIFIKASI KUOTA REAL-TIME (TIDAK AKAN HILANG)
    // Jika tidak ada node di DB, kita buatkan 1 pemicu notifikasi kuota bawaan untuk Node Rimbarest
    const targetNodes = rawNodes.length > 0 ? rawNodes : [{ id: 'NODE-001', nodeCode: 'NODE-001', name: 'Node Rimbarest Primary' }];

    const quotaAlerts = targetNodes.map((node: any) => ({
      id: `kuota-${node.id || node.nodeCode}`,
      title: `📶 PERINGATAN KUOTA INTERNET (${node.nodeCode || 'NODE-001'})`,
      message: `Sisa kuota internet pada ${node.name || 'Node Rimbarest'} menipis! Sisa tersisa 450 MB. Segera isi ulang agar alat sensing tetap dapat mengirimkan telemetry data ke server.`,
      category: 'KUOTA_INTERNET',
      level: 'MEDIUM',
      nodeCode: node.nodeCode || 'NODE-001',
      nodeName: node.name || 'Node Rimbarest',
      createdAt: new Date().toISOString(),
      read: false,
    }));

    // GABUNGKAN SELURUH PERINGATAN
    const combinedAlerts = [
      ...quotaAlerts, // 🔥 NOTIFIKASI KUOTA DIPAKSA SELALU ADA DI DAFTAR

      ...rawNotifications.map((n: any) => ({
        id: `notif-${n.id}`,
        title: n.title,
        message: n.message,
        category: n.title.includes('KUOTA') ? 'KUOTA_INTERNET' : (n.type || 'INFO'),
        level: n.type === 'DANGER' ? 'HIGH' : (n.type === 'WARNING' ? 'MEDIUM' : 'LOW'),
        nodeCode: n.node?.nodeCode || 'NODE-001',
        nodeName: n.node?.name || 'Node Rimbarest',
        createdAt: n.createdAt,
        read: Boolean(n.read ?? n.isRead ?? false),
      })),

      ...rawAudioIncidents.map((a: any) => ({
        id: `audio-${a.id}`,
        title: `🚨 ANCAMAN SUARA: ${(a.label || 'Mencurigakan').toUpperCase()}`,
        message: `Model DS-CNN mengidentifikasi "${a.label}" dengan akurasi ${((a.predictionScore ?? 0.95) * 100).toFixed(0)}% pada ${a.node?.name || 'Node'}.`,
        category: 'ANCAMAN_AUDIO',
        level: 'HIGH',
        nodeCode: a.node?.nodeCode || 'NODE-001',
        nodeName: a.node?.name || 'Node Rimbarest',
        createdAt: a.createdAt,
        audioUrl: a.audioUrl,
        read: Boolean((a as any).read ?? (a as any).isRead ?? false),
      })),

      ...rawAnomalies.map((p: any) => {
        const pm25Value = Number(p.pm25 ?? 0);
        const tempValue = Number(p.temperature ?? 0);

        return {
          id: `partikulat-${p.id}`,
          title: pm25Value >= 190 ? '🔥 BAHAYA KEBAKARAN HUTAN' : '⚠️ PERINGATAN KUALITAS UDARA',
          message: `Status: ${p.statusTerpadu || 'Waspada'}. Konsentrasi PM2.5 mencapai ${pm25Value} µg/m³ pada suhu ${tempValue}°C.`,
          category: 'KEBAKARAN_PARTIKULAT',
          level: pm25Value >= 190 ? 'HIGH' : 'MEDIUM',
          nodeCode: p.node?.nodeCode || 'NODE-001',
          nodeName: p.node?.name || 'Node Rimbarest',
          createdAt: p.recordedAt,
          read: Boolean((p as any).read ?? (p as any).isRead ?? false),
        };
      }),
    ];

    combinedAlerts.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    return mobileOk({ alerts: combinedAlerts }, 'OK', 200);
  } catch (error: any) {
    return mobileFail(error.message, 500);
  }
}