import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic'; // Memaksa Next.js tidak nge-cache status error

// Fungsi inti untuk fetch status ke FastAPI
async function checkFastAPIHealth() {
  try {
    const response = await fetch('http://localhost:8000/health', { 
      cache: 'no-store',
      headers: {
        'Content-Type': 'application/json',
      },
      next: { revalidate: 0 }
    });

    if (!response.ok) {
      return { audio_model: "error", condition_model: "error" };
    }

    const data = await response.json();
    
    // 🔥 SAMAKAN KEY & BOOLEAN DENGAN OUTPUT FASTAPI (/health)
    const isAudioLoaded = data.audio_model_loaded === true;
    const isConditionLoaded = data.condition_pipeline_loaded === true;

    return {
      audio_model: isAudioLoaded ? "loaded" : "error",
      condition_model: isConditionLoaded ? "loaded" : "error"
    };

  } catch (err) {
    return { audio_model: "offline", condition_model: "offline" };
  }
}

// 1. Dukung metode GET
export async function GET() {
  const healthStatus = await checkFastAPIHealth();
  const statusCode = (healthStatus.audio_model === "offline") ? 503 : 200;
  return NextResponse.json(healthStatus, { status: statusCode });
}

// 2. Dukung metode POST
export async function POST() {
  const healthStatus = await checkFastAPIHealth();
  const statusCode = (healthStatus.audio_model === "offline") ? 503 : 200;
  return NextResponse.json(healthStatus, { status: statusCode });
}