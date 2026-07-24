import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic'; // Memaksa Next.js tidak nge-cache status error

// Fungsi inti untuk feth status ke FastAPI
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
    
    return {
      audio_model: data.audio_model === "loaded" ? "loaded" : "error",
      condition_model: data.partikulat_model === "loaded" ? "loaded" : "error"
    };

  } catch (err) {
    return { audio_model: "offline", condition_model: "offline" };
  }
}

// 1. Dukung metode GET (jika ada pemanggilan via URL langsung)
export async function GET() {
  const healthStatus = await checkFastAPIHealth();
  const statusCode = (healthStatus.audio_model === "offline") ? 503 : 200;
  return NextResponse.json(healthStatus, { status: statusCode });
}

// 2. Dukung metode POST (🔥 SOLUSI UTAMA: Mengatasi Error 405 dari hit Dasbor Frontend)
export async function POST() {
  const healthStatus = await checkFastAPIHealth();
  const statusCode = (healthStatus.audio_model === "offline") ? 503 : 200;
  return NextResponse.json(healthStatus, { status: statusCode });
}