import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET() {
  try {
    const nodes = await prisma.deviceNode.findMany({
      include: {
        sensorReadings: {
          orderBy: { recordedAt: 'desc' },
          take: 1
        }
      },
      orderBy: { nodeCode: 'asc' }
    });

    // Looping semua node di peta dan tembak ke AI Python secara massal
    const nodesWithAi = await Promise.all(
      nodes.map(async (node) => {
        const latestReading = node.sensorReadings[0];
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
            console.error(`🚨 AI Server Offline untuk ${node.nodeCode}:`, aiError);
            if ((Number(latestReading.pm25) || 0) > 55) aiStatusResult = "WASPADA KEBAKARAN BESAR";
          }
        }

        return {
          ...node,
          status: aiStatusResult
        };
      })
    );

    return NextResponse.json(nodesWithAi, { status: 200 });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}