import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET(req: NextRequest, { params }: { params: Promise<{ nodeCode: string }> }) {
  try {
    const { nodeCode } = await params;

    const nodeDetails = await prisma.deviceNode.findUnique({
      where: { nodeCode },
      include: {
        sensorReadings: {
          orderBy: { recordedAt: 'desc' },
          take: 10 
        },
        audioIncidents: {
          orderBy: { createdAt: 'desc' },
          take: 5
        }
      }
    });

    if (!nodeDetails) {
      return NextResponse.json({ error: 'Node tidak ditemukan' }, { status: 404 });
    }

    // 🤖 AMBIL DATA TERBARU UNTUK DITEMBAK KE AI SERVER PYTHON (PORT 8000)
    const latestReading = nodeDetails.sensorReadings[0];
    let aiStatusResult = "AMAN";

    if (latestReading) {
      try {
        const aiResponse = await fetch('http://127.0.0.1:8000/predict', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            pm25: Number(latestReading.pm25) || 0,
            noise_level: Number(latestReading.noiseLevel) || 52
          }),
          signal: AbortSignal.timeout(1000)
        });

        if (aiResponse.ok) {
          const aiData = await aiResponse.json();
          aiStatusResult = aiData.status || aiData.prediction || "AMAN";
        }
      } catch (aiError) {
        console.error('🚨 AI Server Offline pada detail route:', aiError);
        if ((Number(latestReading.pm25) || 0) > 55) aiStatusResult = "WASPADA KEBAKARAN BESAR";
      }
    }

    // Sisipkan status AI ke dalam response JSON
    return NextResponse.json({
      ...nodeDetails,
      status: aiStatusResult
    }, { status: 200 });

  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}