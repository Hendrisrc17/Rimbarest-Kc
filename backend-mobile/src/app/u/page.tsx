'use client';

import { useEffect, useState, useRef } from 'react';

interface NodeStatus {
  id: string;
  nodeCode: string;
  name: string | null;
  latitude: number | null;
  longitude: number | null;
  status: string;
  lastSeen: string | null;
}

interface SensorReading {
  id: string;
  recordedAt: string;
  statusTerpadu: string | null; 
  audioLabel: string | null;    
  noiseLevel: number | null;
  pm1?: number | null; 
  pm25: number | null;
  pm10: number | null;
  temperature: number | null;  
  suhu?: number | null;         
  humidity: number | null;     
  kelembapan?: number | null;    
  cacheSource: boolean;
  rawPayload: string | null; 
  node?: NodeStatus | null;
}

export default function MonitorPage() {
  const [readings, setReadings] = useState<SensorReading[]>([]);
  const [nodes, setNodes] = useState<NodeStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [modelsReady, setModelsReady] = useState({ audio: false, condition: false });

  // Referensi Canvas Oskiloskop Frekuensi
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  const latestNoise = readings[0]?.noiseLevel ?? 45; 
  const latestStatusTerpadu = readings[0]?.statusTerpadu || "✅ Normal Bersih";

  // --- PEMISAHAN EVALUASI MODEL 1: DATA PARTIKULAT ---
  const displaySuhu = readings[0]?.temperature ?? readings[0]?.suhu ?? 0;
  const displayLembap = readings[0]?.humidity ?? readings[0]?.kelembapan ?? 0;
  const displayPm25 = readings[0]?.pm25 ?? 0;
  const displayPm10 = readings[0]?.pm10 ?? 0;

  let partikulatStatusText = "🍃 Udara Bersih";
  let partikulatColor = "text-emerald-400 bg-emerald-500/10 border-emerald-500/20";
  
  if (latestStatusTerpadu.includes("Kebakaran") || latestStatusTerpadu.includes("🚨")) {
    partikulatStatusText = "🚨 Bahaya Kebakaran / Asap Pekat";
    partikulatColor = "text-rose-400 bg-rose-500/10 border-rose-500/20 animate-pulse";
  } else if (latestStatusTerpadu.includes("Polusi") || latestStatusTerpadu.includes("⚠️") || latestStatusTerpadu.includes("Tebal")) {
    partikulatStatusText = "⚠️ Polusi / Asap Terdeteksi";
    partikulatColor = "text-amber-400 bg-amber-500/10 border-amber-500/20";
  } else if (latestStatusTerpadu.includes("Berdebu")) {
    partikulatStatusText = "🍃 Normal Berdebu";
    partikulatColor = "text-slate-300 bg-slate-500/10 border-slate-500/20";
  }

  // --- PEMISAHAN EVALUASI MODEL 2: DATA AUDIO MURNI ---
  let latestAudioLabel = "Silence";
  try {
    if (readings[0]?.rawPayload) {
      const parsed = JSON.parse(readings[0].rawPayload);
      if (parsed.aiDetectedAudioLabel) {
        latestAudioLabel = parsed.aiDetectedAudioLabel;
      } else if (parsed.aiLabelDetected) {
        latestAudioLabel = parsed.aiLabelDetected;
      }
    } else {
      latestAudioLabel = readings[0]?.audioLabel || "Silence";
    }
  } catch (e) {
    latestAudioLabel = readings[0]?.audioLabel || "Silence";
  }

  const isThreatAudio = ["Chainsaw", "Axe", "Handsaw", "Engine", "WoodChp", "Gen", "Gunshot", "TreeFall"].includes(latestAudioLabel);

  // ENGINE GRAPHIC REAL-TIME 60FPS
  useEffect(() => {
    let animationFrameId: number;
    let timePhase = 0;

    const renderOscilloscope = () => {
      const canvas = canvasRef.current;
      if (!canvas) return;
      const ctx = canvas.getContext('2d');
      if (!ctx) return;

      const w = canvas.width;
      const h = canvas.height;

      ctx.clearRect(0, 0, w, h);
      ctx.fillStyle = '#020617';
      ctx.fillRect(0, 0, w, h);

      ctx.strokeStyle = '#1e293b';
      ctx.lineWidth = 0.5;
      const gridOffset = (timePhase * 25) % 40;
      for (let i = -gridOffset; i < w; i += 40) {
        ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, h); ctx.stroke();
      }
      for (let j = 0; j < h; j += 20) {
        ctx.beginPath(); ctx.moveTo(0, j); ctx.lineTo(w, j); ctx.stroke();
      }

      const thresholdY = h - ((70 / 120) * h);
      ctx.strokeStyle = 'rgba(239, 68, 68, 0.4)';
      ctx.setLineDash([4, 4]);
      ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(0, thresholdY); ctx.lineTo(w, thresholdY); ctx.stroke();
      ctx.setLineDash([]);

      ctx.beginPath();
      ctx.lineWidth = 2;

      ctx.strokeStyle = isThreatAudio ? '#f43f5e' : latestAudioLabel !== "Silence" ? '#fbbf24' : '#10b981';

      const totalPoints = 160;
      const step = w / totalPoints;
      
      ctx.moveTo(0, h / 2);

      for (let i = 0; i <= totalPoints; i++) {
        const x = i * step;
        
        const n1 = Math.sin(i * 0.9 + timePhase * 35);
        const n2 = Math.cos(i * 1.7 - timePhase * 20);
        const n3 = Math.sin(i * 3.1 + timePhase * 50);
        
        const rawSpike = Math.abs(n1 * 0.5 + n2 * 0.3 + n3 * 0.2); 

        const baseAmplitude = (latestNoise / 120) * (h * 0.8);
        const envelope = 0.4 + 0.6 * Math.sin(i * 0.04 + timePhase * 2);
        
        const displacement = rawSpike * baseAmplitude * envelope;
        const y = h / 2 + (i % 2 === 0 ? displacement : -displacement);

        ctx.lineTo(x, Math.min(Math.max(y, 4), h - 4));
      }
      ctx.stroke();

      const grad = ctx.createLinearGradient(0, 0, 0, h);
      grad.addColorStop(0, isThreatAudio ? 'rgba(244, 63, 94, 0.08)' : 'rgba(16, 185, 129, 0.04)');
      grad.addColorStop(1, 'rgba(2, 6, 23, 0)');
      ctx.fillStyle = grad;
      ctx.fill();

      timePhase += 0.04; 
      animationFrameId = requestAnimationFrame(renderOscilloscope);
    };

    renderOscilloscope();
    return () => cancelAnimationFrame(animationFrameId);
  }, [latestNoise, latestAudioLabel, isThreatAudio]);

  // Sinkronisasi data ke database & FastAPI
  useEffect(() => {
    async function checkModelStatus() {
      try {
        const res = await fetch('/api/health-check-backend'); 
        if (res.ok) {
          const data = await res.json();
          // 🔧 FIX: Mentoleransi properti kunci JSON 'partikulat_model' atau 'condition_model' secara aman
          const isAudioReady = data.audio_model?.includes("loaded") || data.audio?.includes("loaded") || false;
          const isConditionReady = data.partikulat_model?.includes("loaded") || data.condition_model?.includes("loaded") || data.partikulat?.includes("loaded") || false;
          
          setModelsReady({
            audio: isAudioReady,
            condition: isConditionReady
          });
        }
      } catch (err) {
        setModelsReady({ audio: false, condition: false });
      }
    }

    async function fetchData() {
      try {
        const res = await fetch('/api/monitoring');
        if (res.ok) {
          const data = await res.json();
          setReadings(data.readings || []);
          setNodes(data.nodes || []);
        }
      } catch (err) {
        console.error("Gagal mengambil data monitoring:", err);
      } finally {
        setLoading(false);
      }
    }

    checkModelStatus();
    fetchData();

    const interval = setInterval(() => {
      fetchData();
      checkModelStatus(); 
    }, 2000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 p-6 font-sans">
      <div className="max-w-7xl mx-auto">
        
        {/* Header Dashboard */}
        <header className="flex justify-between items-center mb-8 border-b border-slate-800 pb-5">
          <div>
            <h1 className="text-3xl font-extrabold tracking-tight text-white flex items-center gap-2">
              🍃 RIMBAREST Monitor <span className="text-xs bg-emerald-500/10 text-emerald-400 px-2 py-1 rounded border border-emerald-500/20 font-mono animate-pulse">LIVE</span>
            </h1>
            <p className="text-sm text-slate-400 mt-1">
              Verifikasi Integrasi Terpisah: Komparasi Mandiri Data Partikulat Udara & Hasil Spektrogram Klasifikasi Audio.
            </p>
          </div>
          <div className="text-xs text-slate-500 bg-slate-950 p-2 rounded font-mono flex items-center gap-2">
            <span>Auto-refresh: 2s</span>
            {!loading && <span className="h-2 w-2 rounded-full bg-emerald-500 animate-ping" />}
          </div>
        </header>

        {/* ================= SECTION 1: PEMISAHAN VALIDASI MODEL RAM ================= */}
        <section className="mb-8 bg-slate-950 border border-slate-800 p-4 rounded-xl">
          <h2 className="text-sm font-bold tracking-wide uppercase text-slate-400 mb-3 flex items-center gap-2">
            🤖 Pembagian Validasi Independen Model AI Server (FastAPI CMD Engine)
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className={`p-3 rounded-lg border text-sm transition-all flex items-center gap-3 ${
              modelsReady.audio 
                ? 'bg-sky-500/10 text-sky-400 border-sky-500/20' 
                : 'bg-rose-500/10 text-rose-400 border-rose-500/20 animate-pulse'
            }`}>
              <span className="text-lg">{modelsReady.audio ? "🔊" : "❌"}</span>
              <div>
                <strong className="block font-semibold">1. Subsistem AI Klasifikasi Audio (.h5)</strong>
                <span className="text-xs opacity-80">
                  {modelsReady.audio ? 'Loaded: Convolutional Neural Network Siap Analisis Spektrogram' : 'Offline: Kegagalan Inisialisasi Berkas Model Audio'}
                </span>
              </div>
            </div>

            <div className={`p-3 rounded-lg border text-sm transition-all flex items-center gap-3 ${
              modelsReady.condition 
                ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20' 
                : 'bg-rose-500/10 text-rose-400 border-rose-500/20 animate-pulse'
            }`}>
              <span className="text-lg">{modelsReady.condition ? "🍃" : "❌"}</span>
              <div>
                <strong className="block font-semibold">2. Subsistem AI Klasifikasi Partikulat (.joblib)</strong>
                <span className="text-xs opacity-80">
                  {modelsReady.condition ? 'Loaded: Pipeline Isolation Forest & Bins Matriks Udara Aktif' : 'Offline: Berkas Pipeline Partikulat Tidak Ditemukan'}
                </span>
              </div>
            </div>
          </div>
        </section>

        {/* ================= SECTION 2: LIVE MONITORING BOX TINGKAT AKTUAL TERPISAH ================= */}
        <section className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          
          {/* Panel Blok A: Hasil Deteksi Partikulat Udara */}
          <div className="bg-slate-950 border border-slate-800 p-5 rounded-xl flex flex-col justify-between">
            <div>
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-xs font-bold tracking-wider uppercase text-emerald-400 flex items-center gap-1">
                  📊 A. Status Komponen Partikulat Udara (Live)
                </h3>
                <span className={`px-2 py-0.5 rounded text-[11px] font-semibold border ${partikulatColor}`}>
                  {partikulatStatusText}
                </span>
              </div>
              <div className="grid grid-cols-2 gap-4 text-sm font-mono bg-slate-900/50 p-3 rounded-lg border border-slate-800/60">
                <div>
                  <span className="text-slate-500 block text-xs">PM2.5 Riil:</span>
                  <strong className="text-lg text-slate-100">{displayPm25} µg/m³</strong>
                </div>
                <div>
                  <span className="text-slate-500 block text-xs">PM10 Riil:</span>
                  <strong className="text-lg text-slate-100">{displayPm10} µg/m³</strong>
                </div>
                <div className="border-t border-slate-800/80 pt-2 mt-1">
                  <span className="text-slate-500 block text-xs">Suhu Lapangan:</span>
                  <strong className="text-slate-200">{displaySuhu} °C</strong>
                </div>
                <div className="border-t border-slate-800/80 pt-2 mt-1">
                  <span className="text-slate-500 block text-xs">Kelembapan:</span>
                  <strong className="text-slate-200">{displayLembap} %</strong>
                </div>
              </div>
            </div>
            <p className="text-[11px] text-slate-500 font-mono mt-3 italic">
              *Metrik di atas dihitung murni menggunakan algoritma Isolation Forest & Bins Karbondioksida Udara.
            </p>
          </div>

          {/* Panel Blok B: Hasil Deteksi Isyarat Gelombang Audio */}
          <div className="bg-slate-950 border border-slate-800 p-5 rounded-xl flex flex-col justify-between">
            <div>
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-xs font-bold tracking-wider uppercase text-sky-400 flex items-center gap-1">
                  🔊 B. Hasil Analisis Pola Audio Spektrogram (Live)
                </h3>
                <span className={`px-2 py-0.5 rounded text-[11px] font-bold border font-mono ${
                  isThreatAudio ? 'bg-rose-500/10 text-rose-400 border-rose-500/20 animate-pulse' : 'bg-slate-900 text-slate-400 border-slate-800'
                }`}>
                  LABEL AI: {latestAudioLabel.toUpperCase()}
                </span>
              </div>
              <div className="bg-slate-900/50 p-3 rounded-lg border border-slate-800/60 font-mono text-sm flex flex-col gap-2">
                <div className="flex justify-between items-center">
                  <span className="text-slate-500 text-xs">Kebisingan Hardware:</span>
                  <span className="text-slate-100 font-bold text-base">{latestNoise.toFixed(4)} dB</span>
                </div>
                <div className="flex justify-between items-center border-t border-slate-800/80 pt-2 mt-1">
                  <span className="text-slate-500 text-xs">Status Ancaman Audio:</span>
                  <span className={`font-semibold text-xs ${isThreatAudio ? 'text-rose-400' : 'text-emerald-400'}`}>
                    {isThreatAudio ? '⚠️ Terdeteksi Ancaman Pembalakan Wild!' : '✅ Kondisi Hutan Aman'}
                  </span>
                </div>
              </div>
            </div>
            <p className="text-[11px] text-slate-500 font-mono mt-3 italic">
              *Klasifikasi audio murni dicocokkan berdasarkan visual ekstraksi MelSpectrogram 8000Hz model (.h5).
            </p>
          </div>

        </section>

        {/* Visualizer Window */}
        <section className="mb-8 bg-slate-950 border border-slate-800 p-5 rounded-xl">
          <div className="flex justify-between items-center mb-3">
            <h2 className="text-sm font-bold tracking-wide uppercase text-slate-300 flex items-center gap-2">
              📊 Visualisasi Radar Amplitudo Mikrofon MAX9814 (Oskiloskop Frekuensi Lancip)
            </h2>
            <span className="text-xs text-slate-400 font-mono bg-slate-900 px-2 py-0.5 rounded border border-slate-800">
              Sistem Terpadu Gabungan: <strong className="text-slate-200">{latestStatusTerpadu}</strong>
            </span>
          </div>
          
          <div className="w-full bg-slate-950 rounded-lg border border-slate-800 overflow-hidden">
            <canvas 
              ref={canvasRef} 
              width={1000} 
              height={150} 
              className="w-full h-[150px] block"
            />
          </div>

          <div className="mt-3 p-3 bg-slate-900 rounded-lg border border-slate-800 flex justify-between items-center text-xs">
            <span className="text-slate-400 font-mono">🧪 Uji Validitas Spektrogram Model (.h5) Via Router FastAPI Internal Server:</span>
            <input 
              type="file" 
              accept="audio/wav"
              onChange={async (e) => {
                const file = e.target.files?.[0];
                if (!file) return;

                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = async () => {
                  const base64Audio = (reader.result as string).split(',')[1];

                  try {
                    const res = await fetch('/api/iot/sensor', {
                      method: 'POST',
                      headers: { 'Content-Type': 'application/json' },
                      body: JSON.stringify({
                        nodeCode: 'NODE-001',
                        pm1: 14.5,
                        pm25: 16.0, 
                        pm10: 21.0,
                        suhu: 27.5,
                        kelembapan: 60.0,
                        noiseLevel: 85.1234, 
                        audioBase64: base64Audio
                      })
                    });

                    if (res.ok) {
                      const jsonRes = await res.json();
                      alert(`✅ AI PREDICTION DONE!\nLabel Spektrogram: ${jsonRes.aiLabelDetected}\nStatus Terpadu: ${jsonRes.aiStatusResult}`);
                      
                      const updateRes = await fetch('/api/monitoring');
                      if (updateRes.ok) {
                        const freshData = await updateRes.json();
                        setReadings(freshData.readings || []);
                        setNodes(freshData.nodes || []);
                      }
                    } else {
                      const errData = await res.json();
                      alert(`❌ Gagal memproses: ${errData.error || 'Internal Error'}`);
                    }
                  } catch (err) {
                    alert("❌ Hubungan terputus dari server Next.js.");
                  }
                };
              }}
              className="text-slate-300 file:mr-4 file:py-1 file:px-3 file:rounded-md file:border-0 file:text-xs file:font-semibold file:bg-sky-500/10 file:text-sky-400 hover:file:bg-sky-500/20 cursor-pointer font-mono"
            />
          </div>
        </section>

        {/* Grid Status Node Aktif */}
        <section className="mb-8">
          <h2 className="text-lg font-semibold mb-4 text-slate-300">Status Node Aktif</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {nodes.map((node) => (
              <div key={node.id} className="bg-slate-950 border border-slate-800 rounded-xl p-4 flex justify-between items-center">
                <div>
                  <p className="font-mono text-xs text-slate-500">{node.nodeCode}</p>
                  <h3 className="font-bold text-slate-200">{node.name || 'Sensor Area'}</h3>
                  <p className="text-xs text-slate-400 mt-1">
                    Lat: {node.latitude ? String(node.latitude) : '-'} | Lon: {node.longitude ? String(node.longitude) : '-'}
                  </p>
                </div>
                <div className="flex flex-col items-end gap-1">
                  <span className={`px-2 py-0.5 text-xs font-semibold rounded-full ${
                    node.status === 'ONLINE' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                  }`}>
                    {node.status}
                  </span>
                  <span className="text-[10px] text-slate-500 font-mono">
                    {node.lastSeen ? new Date(node.lastSeen).toLocaleTimeString() : 'Never'}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* ================= SECTION 3: TABEL PEMISAHAN LOG DETEKSI DATA ================= */}
        <section>
          <h2 className="text-lg font-semibold mb-4 text-slate-300">10 Log Hasil Validasi Terpisah AI Terkini</h2>
          <div className="overflow-x-auto bg-slate-950 border border-slate-800 rounded-xl">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-800 bg-slate-900/50 text-slate-400 text-xs font-semibold uppercase tracking-wider">
                  <th className="p-4">Waktu</th>
                  <th className="p-4">Node / Lokasi</th>
                  <th className="p-4 text-center bg-slate-900/30 border-x border-slate-800/60 text-emerald-400 font-bold">Model 1: Partikulat Udara (Live Sensor)</th>
                  <th className="p-4 text-center text-sky-400 font-bold">Model 2: Audio Spektrogram (AI Output)</th>
                  <th className="p-4 text-center bg-slate-900/60 border-l border-slate-800">Output Terpadu Sistem</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800 text-sm">
                {readings.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="p-8 text-center text-slate-500 font-mono text-xs">
                      {loading ? 'Mensinkronisasikan komponen internal data...' : 'Belum ada data sensor masuk dari stasiun node.'}
                    </td>
                  </tr>
                ) : (
                  readings.map((reading) => {
                    const statusTerpaduText = reading.statusTerpadu || '✅ Normal Bersih';
                    
                    let rawAudioLabel = 'Silence';
                    try {
                      if (reading.rawPayload) {
                        const parsed = JSON.parse(reading.rawPayload);
                        if (parsed.aiDetectedAudioLabel) {
                          rawAudioLabel = parsed.aiDetectedAudioLabel;
                        } else if (parsed.aiLabelDetected) {
                          rawAudioLabel = parsed.aiLabelDetected;
                        }
                      }
                    } catch (e) {
                      rawAudioLabel = reading.audioLabel || 'Silence';
                    }

                    const noise = reading.noiseLevel ?? 0;
                    const pm25 = reading.pm25 ?? 0;
                    const pm10 = reading.pm10 ?? 0;
                    const rowSuhu = reading.temperature ?? reading.suhu ?? 0;
                    const rowLembap = reading.humidity ?? reading.kelembapan ?? 0;

                    let statusColor = "bg-emerald-950/60 text-emerald-400 border border-emerald-900";
                    if (statusTerpaduText.includes("CRITICAL") || statusTerpaduText.includes("🚨🚨")) {
                      statusColor = "bg-rose-950 text-rose-300 border border-rose-500/50 animate-pulse font-bold";
                    } else if (statusTerpaduText.includes("🚨") || statusTerpaduText.includes("Peringatan")) {
                      statusColor = "bg-rose-950/50 text-rose-400 border border-rose-900";
                    } else if (statusTerpaduText.includes("⚠️") || statusTerpaduText.includes("Waspada") || statusTerpaduText.includes("Investigasi")) {
                      statusColor = "bg-amber-950/60 text-amber-400 border border-amber-800";
                    }

                    let audioLabelFormatted = `🔊 AI: ${rawAudioLabel}`;
                    let audioColor = "bg-slate-900 text-slate-300 border border-slate-800";

                    if (["Chainsaw", "Handsaw", "Axe", "TreeFall"].includes(rawAudioLabel)) {
                      audioLabelFormatted = `🚨 AI: ${rawAudioLabel.toUpperCase()} (KRITIS)`;
                      audioColor = "bg-rose-500/10 text-rose-400 border border-rose-500/30 font-extrabold";
                    } else if (["Engine", "Gen", "Gunshot", "WoodChp"].includes(rawAudioLabel)) {
                      audioLabelFormatted = `⚠️ AI: ${rawAudioLabel} (Ancaman)`;
                      audioColor = "bg-amber-500/10 text-amber-400 border border-amber-500/30 font-bold";
                    } else if (["Bird", "Frog", "Insect", "Squirrel", "Lion", "Wolf"].includes(rawAudioLabel)) {
                      audioLabelFormatted = `🍃 AI: Fauna (${rawAudioLabel})`;
                      audioColor = "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20";
                    } else if (rawAudioLabel === "Silence") {
                      audioLabelFormatted = "💤 AI: Ambient Sunyi";
                      audioColor = "bg-slate-950 text-slate-500 border border-slate-900 font-mono";
                    }

                    return (
                      <tr key={reading.id} className="hover:bg-slate-900/40 transition-colors">
                        <td className="p-4 font-mono text-xs text-slate-400">
                          {new Date(reading.recordedAt).toLocaleTimeString()}
                        </td>
                        <td className="p-4">
                          <div className="font-semibold text-slate-200">{reading.node?.name || 'Stasiun Rimba'}</div>
                          <div className="font-mono text-xs text-slate-500">{reading.node?.nodeCode || 'NODE-XYZ'}</div>
                        </td>
                        
                        <td className="p-4 bg-slate-900/20 border-x border-slate-800/60">
                          <div className="grid grid-cols-2 gap-x-3 gap-y-0.5 text-xs font-mono">
                            <span className="text-slate-400">PM2.5: <strong className="text-slate-200">{pm25}</strong></span>
                            <span className="text-slate-400">Suhu: <strong className="text-slate-200">{rowSuhu}°C</strong></span>
                            <span className="text-slate-400">PM10: <strong className="text-slate-200">{pm10}</strong></span>
                            <span className="text-slate-400">Lembap: <strong className="text-slate-200">{rowLembap}%</strong></span>
                          </div>
                        </td>
                        
                        <td className="p-4 text-center">
                          <div className="flex flex-col items-center gap-1">
                            <span className={`inline-block px-3 py-1 rounded-lg font-medium text-xs w-full max-w-[210px] ${audioColor}`}>
                              {audioLabelFormatted}
                            </span>
                            <span className="text-[11px] text-slate-400 font-mono">Amplitudo: {noise.toFixed(2)} dB</span>
                          </div>
                        </td>

                        <td className="p-4 text-center bg-slate-900/40 border-l border-slate-800">
                          <span className={`inline-block px-3 py-1 rounded-lg font-medium text-xs w-full max-w-[220px] ${statusColor}`}>
                            {statusTerpaduText}
                          </span>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </section>
        
      </div>
    </div>
  );
}