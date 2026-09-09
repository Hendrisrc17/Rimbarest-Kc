export interface AIRecordResult {
  statusTerpadu: string;
  audioLabel: string;
  kategoriAsap: string;
  isAnomaly: boolean;
}

/**
 * Helper untuk menambahkan header WAV 44-byte ke PCM mentah dari IoT
 */
function wrapPcmWithWavHeader(pcmBuffer: Buffer, sampleRate = 22050, bitsPerSample = 16, channels = 1): Buffer {
  const header = Buffer.alloc(44);
  const blockAlign = (channels * bitsPerSample) / 8;
  const byteRate = sampleRate * blockAlign;
  const dataSize = pcmBuffer.length;

  header.write('RIFF', 0);
  header.writeUInt32LE(36 + dataSize, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16); 
  header.writeUInt16LE(1, 20); // Audio format (1 = PCM)
  header.writeUInt16LE(channels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(byteRate, 28);
  header.writeUInt16LE(blockAlign, 32);
  header.writeUInt16LE(bitsPerSample, 34);
  header.write('data', 36);
  header.writeUInt32LE(dataSize, 40);

  return Buffer.concat([header, pcmBuffer]);
}

export async function evaluateIntegratedConditionWithAI(
  pm1: number,
  pm25: number,
  pm10: number,
  suhu: number,
  kelembapan: number,
  audioBuffer: Buffer | null,
  nodeCode: string = 'NODE-001'
): Promise<AIRecordResult> {
  try {
    const AI_SERVER_URL = (process.env.AI_SERVER_URL || 'http://localhost:8000/predict')
      .replace(/\/predict$/, '');
      
    const formData = new FormData();
    formData.append('pm1', String(pm1 ?? 0));
    formData.append('pm25', String(pm25 ?? 0));
    formData.append('pm10', String(pm10 ?? 0));
    formData.append('suhu', String(suhu ?? 0));
    formData.append('kelembapan', String(kelembapan ?? 0));
    formData.append('label_audio_ai', 'Silence'); 

    if (audioBuffer && audioBuffer.length > 0) {
      let finalAudioBuffer = audioBuffer;
      const isWav = audioBuffer.slice(0, 4).toString('ascii') === 'RIFF';
      
      if (!isWav) {
        // 🚨 SESUAIKAN KEMBALI: Jika ESP32 merekam dengan 16000Hz, ganti 22050 menjadi 16000
        finalAudioBuffer = wrapPcmWithWavHeader(audioBuffer, 22050, 16, 1);
      }

      // 🔥 SOLUSI UTAMA BEBAS SILENT-DROP DI NEXT.JS SERVER:
      // Ubah data biner langsung ke format File Node standard menggunakan constructor Blob global 
      // yang diekstrak tipe datanya secara eksplisit melalui Array/Buffer
      const audioArray = new Uint8Array(finalAudioBuffer);
      const audioBlob = new Blob([audioArray], { type: 'audio/wav' });
      
      // Bungkus ke objek File standard agar ter-serialisasi sempurna di Multipart HTTP request
      const fileToUpload = new File([audioBlob], `${nodeCode}_live_hardware.wav`, { type: 'audio/wav' });
      formData.append('file', fileToUpload);
      
      console.log(`[AI-CLIENT SUCCESS] Mengirim biner multipart. Total ukuran: ${finalAudioBuffer.byteLength} bytes.`);
    } else {
      console.log(`[AI-CLIENT WARNING] Request IoT masuk tanpa menyertakan payload audioBase64.`);
    }

    const response = await fetch(`${AI_SERVER_URL}/evaluate-condition`, {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      throw new Error(`FastAPI Server AI merespons dengan status: ${response.status}`);
    }

    const result = await response.json();
    
    return {
      statusTerpadu: result.status,
      audioLabel: result.audioLabel || 'Silence',
      kategoriAsap: Array.isArray(result.kategoriAsap) ? result.kategoriAsap[0] : (result.kategoriAsap || 'Udara Bersih'),
      isAnomaly: result.isAnomaly ?? false
    };

  } catch (error) {
    console.error('❌ Gagal sinkronisasi otomatis dengan FastAPI Server AI:', error);
    return {
      statusTerpadu: '🔍 Anomali Alat/Cuaca',
      audioLabel: 'Silence',
      kategoriAsap: 'Udara Bersih',
      isAnomaly: false
    };
  }
}