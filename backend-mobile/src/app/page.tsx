'use client';

import React, { useState, useEffect } from 'react';

// ==========================================
// 1. KOMPONEN TABEL DETEKSI AI (ADAPTIF TERHADAP STRUKTUR DATA SENSOR)
// ==========================================
export function DashboardTable({ logs }: { logs: any }) {
  // Pengecekan mendalam untuk membongkar array log di dalam objek API
  let arrayLogs: any[] = [];
  
  if (Array.isArray(logs)) {
    arrayLogs = logs;
  } else if (logs && typeof logs === 'object') {
    if (Array.isArray(logs.logs)) {
      arrayLogs = logs.logs;
    } else if (Array.isArray(logs.data)) {
      arrayLogs = logs.data;
    } else if (Array.isArray(logs.readings)) {
      arrayLogs = logs.readings;
    } else if (logs.result && Array.isArray(logs.result)) {
      arrayLogs = logs.result;
    } else if (logs.result && typeof logs.result === 'object' && Array.isArray(logs.result.logs)) {
      arrayLogs = logs.result.logs;
    }
  }

  return (
    <div className="overflow-x-auto w-full bg-slate-950 p-4 rounded-lg">
      <table className="min-w-full divide-y divide-slate-800 text-sm text-left text-slate-300">
        <thead className="bg-slate-900/50 text-xs uppercase text-slate-400">
          <tr>
            <th className="px-6 py-3">Waktu</th>
            <th className="px-6 py-3">Node / Lokasi</th>
            <th className="px-6 py-3">Data Lingkungan</th>
            <th className="px-6 py-3">Kebisingan</th>
            <th className="px-6 py-3">Tipe Data</th>
            <th className="px-6 py-3">Status Terpadu (Sistem AI)</th>
            <th className="px-6 py-3">Deteksi Audio Murni (AI Output)</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800">
          {arrayLogs.map((log) => {
            if (!log) return null;

            // Membongkar log terenkapsulasi string JSON di database
            let payload: any = {};
            try {
              payload = log.rawPayload ? JSON.parse(log.rawPayload) : {};
            } catch (e) {
              payload = {};
            }

            const audioLabel = payload.aiDetectedAudioLabel || log.aiLabelDetected || "Silence";
            const audioScore = payload.aiAudioPredictionScore || "0.00%";
            const partikulatScore = payload.aiPartikulatPredictionScore || "0.00%";
            
            const daftarAncaman = ["Chainsaw", "Axe", "Handsaw", "Engine", "WoodChp", "Gen", "Gunshot", "TreeFall"];
            const isThreat = daftarAncaman.some(threat => audioLabel.toLowerCase().includes(threat.toLowerCase()));

            return (
              <tr key={log.id || Math.random()} className="hover:bg-slate-900/40 transition-colors">
                <td className="px-6 py-4 whitespace-nowrap text-slate-500">
                  {log.recordedAt ? new Date(log.recordedAt).toLocaleTimeString() : '-'}
                </td>
                <td className="px-6 py-4">
                  <div className="font-semibold text-slate-200">Device Backup {log.nodeCode || 'NODE-001'}</div>
                  <div className="text-xs text-slate-500">{log.nodeCode || log.nodeId || 'NODE-001'}</div>
                </td>
                <td className="px-6 py-4">
                  <div className="text-xs">PM2.5: <span className="font-bold text-slate-100">{log.pm25 ?? 0}</span></div>
                  <div className="text-xs">PM10: <span className="font-bold text-slate-100">{log.pm10 ?? 0}</span></div>
                  <div className="text-xs text-slate-400">Suhu: {log.temperature ?? log.suhu ?? 0}°C | Lembap: {log.humidity ?? log.kelembapan ?? 0}%</div>
                </td>
                <td className="px-6 py-4 font-mono font-bold text-yellow-500">
                  {log.noiseLevel ? Number(log.noiseLevel).toFixed(4) : '0.0000'} dB
                </td>
                <td className="px-6 py-4">
                  <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-blue-950/60 text-blue-400 border border-blue-800">
                    {log.cacheSource ? 'Cache' : 'Real-Time'}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2">
                    <span className={`px-3 py-1.5 rounded text-xs font-semibold ${
                      String(log.statusTerpadu).includes('🚨') || String(log.statusTerpadu).includes('⚠️')
                        ? 'bg-amber-950/30 text-amber-400 border border-amber-800'
                        : 'bg-emerald-950/30 text-emerald-400 border border-emerald-800'
                    }`}>
                      {log.statusTerpadu || '✅ Normal Bersih'}
                    </span>
                    <span className="text-[10px] text-slate-500 font-mono">({partikulatScore})</span>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2">
                    <span className={`px-3 py-1.5 rounded text-xs font-semibold ${
                      isThreat 
                        ? 'bg-red-950/50 text-red-400 border border-red-800 font-bold' 
                        : 'bg-slate-900 text-slate-400 border border-slate-700'
                    }`}>
                      {isThreat ? `🚨 AI: ${audioLabel} (Ancaman)` : `🔊 AI: ${audioLabel}`}
                    </span>
                    <span className="text-[10px] text-slate-500 font-mono">({audioScore})</span>
                  </div>
                </td>
              </tr>
            );
          })}

          {arrayLogs.length === 0 && (
            <tr>
              <td colSpan={7} className="px-6 py-8 text-center text-slate-500 italic">
                Belum ada data log AI yang tersinkronisasi...
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

// ==========================================
// 2. MAIN DASHBOARD PAGE WRAPPER
// ==========================================
export default function MonitorPage() {
  const [dataLogs, setDataLogs] = useState<any>([]);
  const [modelStatus, setModelStatus] = useState({ audio: 'loading', partikulat: 'loading' });

  const fetchDashboardData = async () => {
    try {
      const resData = await fetch('/api/monitoring');
      if (resData.ok) {
        const result = await resData.json();
        setDataLogs(result);
      }

      const resHealth = await fetch('/api/health-check-backend', { method: 'POST' });
      if (resHealth.ok) {
        const health = await resHealth.json();
        setModelStatus({
          audio: health.audio_model,
          partikulat: health.condition_model
        });
      }
    } catch (err) {
      console.error("Gagal melakukan polling sinkronisasi data dashboard:", err);
    }
  };

  useEffect(() => {
    fetchDashboardData();
    const interval = setInterval(fetchDashboardData, 2000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 p-8 space-y-8">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
          🌲 RIMBAREST Monitor <span className="bg-emerald-500 text-slate-950 text-[10px] font-bold px-1.5 py-0.5 rounded">LIVE</span>
        </h1>
        <p className="text-xs text-slate-400 mt-1">
          Verifikasi Integrasi Terpisah: Evaluasi Partikulat Udara & Hasil Klasifikasi Audio 20-Kelas Latih Model.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className={`p-4 rounded-lg border flex items-center gap-3 ${modelStatus.audio === 'loaded' ? 'bg-emerald-950/20 border-emerald-800 text-emerald-400' : 'bg-red-950/20 border-red-900 text-red-400'}`}>
          <div className="text-xl">{modelStatus.audio === 'loaded' ? '✅' : '❌'}</div>
          <div>
            <div className="font-bold text-sm">Model AI Suara Hub (.h5)</div>
            <div className="text-xs opacity-80">{modelStatus.audio === 'loaded' ? 'Loaded: Model Masuk & Siap Ekstraksi Multi-Kelas' : 'Error: File .h5 Tidak Ditemukan / Server Offline'}</div>
          </div>
        </div>
        
        <div className={`p-4 rounded-lg border flex items-center gap-3 ${modelStatus.partikulat === 'loaded' ? 'bg-emerald-950/20 border-emerald-800 text-emerald-400' : 'bg-red-950/20 border-red-900 text-red-400'}`}>
          <div className="text-xl">{modelStatus.partikulat === 'loaded' ? '✅' : '❌'}</div>
          <div>
            <div className="font-bold text-sm">Model Partikulat Hutan (.joblib)</div>
            <div className="text-xs opacity-80">{modelStatus.partikulat === 'loaded' ? 'Loaded: Pipeline ML Hutan Aktif' : 'Error: Berkas .joblib Belum Termuat Sempurna'}</div>
          </div>
        </div>
      </div>

      <div>
        <h2 className="text-lg font-semibold text-white mb-3">10 Log Deteksi AI Terbaru</h2>
        <DashboardTable logs={dataLogs} />
      </div>
    </div>
  );
}