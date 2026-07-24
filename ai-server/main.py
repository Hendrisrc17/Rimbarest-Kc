import io
import os
import datetime
import joblib
import numpy as np
import pandas as pd
import wave
import soundfile as sf
from dotenv import load_dotenv
from contextlib import asynccontextmanager
from fastapi import FastAPI, File, Form, UploadFile, BackgroundTasks, Request
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import httpx

# 🔥 WAJIB DIPANGGIL PALING AWAL, SEBELUM os.getenv() DIPAKAI DI MANA PUN
load_dotenv()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "..", "Model_rimbarest")
DEBUG_AUDIO_DIR = os.path.join(BASE_DIR, "debug_iot_audio")
os.makedirs(DEBUG_AUDIO_DIR, exist_ok=True)

condition_pipeline = None
kategori_bins = None
kategori_labels = None
DEFAULT_SUHU_MINIMAL_OUTDOOR = 27.0
audio_model = None

NODE_DATA_BUFFER = {}

# =====================================================================
# 🔥 PARAMETER AUDIO — HARUS 100% SAMA DENGAN NOTEBOOK TRAINING 🔥
# =====================================================================
SR = 22050
DURATION_TARGET = 5  # detik
N_MELS = 128
FMAX = 8000
IMG_SIZE = 128
NATIVE_DEVICE_SR = 8000  # fallback KHUSUS untuk raw PCM tanpa header WAV

FAST_PREDICT_TIMEOUT_SECONDS = 10.0
FITUR_LATIH = ["PM1.0", "PM2.5", "PM10", "Suhu(C)", "Kelembapan(%)"]

# =====================================================================
# 🔥 MODEL BINARY (Dense(1, activation='sigmoid')) 🔥
# =====================================================================
CLASS_NAMES_BINARY = ["negatif", "positif"]
THRESHOLD_POSITIF = 0.5

LABEL_NEGATIF = "Normal Ambient"
LABEL_POSITIF = "Ancaman Terdeteksi"
LABEL_SILENCE = "Silence"


def _resolve_model_path(filename: str) -> str:
    candidates = [
        os.path.join(MODEL_DIR, filename),
        os.path.join(BASE_DIR, "Model_rimbarest", filename),
    ]
    for path in candidates:
        if os.path.exists(path):
            return path
    return candidates[0]


def load_audio_model_safely():
    import tensorflow as tf
    path = _resolve_model_path("model_ds_cnn_rimbarest_fsc22.h5")
    if not os.path.exists(path):
        print("❌ [MODEL ERROR] File model DS-CNN audio tidak ditemukan!")
        return None
    try:
        class PatchedBatchNormalization(tf.keras.layers.BatchNormalization):
            def __init__(self, **kwargs):
                kwargs.pop("renorm", None)
                kwargs.pop("renorm_clipping", None)
                kwargs.pop("renorm_momentum", None)
                super().__init__(**kwargs)

        class PatchedDense(tf.keras.layers.Dense):
            def __init__(self, **kwargs):
                kwargs.pop("quantization_config", None)
                super().__init__(**kwargs)

        model = tf.keras.models.load_model(
            path,
            custom_objects={"BatchNormalization": PatchedBatchNormalization, "Dense": PatchedDense},
            compile=False,
        )
        print(f"✅ [MODEL LOADED] Berhasil memuat DS-CNN Model dari: {path}")

        out_shape = model.output_shape
        n_units = out_shape[-1] if isinstance(out_shape, tuple) else out_shape[0][-1]
        if n_units != 1:
            print(f"⚠️ [MODEL WARNING] Model punya {n_units} output unit!")

        return model
    except Exception as exc:
        print(f"❌ [MODEL ERROR] Gagal memuat audio model: {exc}")
        return None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global condition_pipeline, kategori_bins, kategori_labels, DEFAULT_SUHU_MINIMAL_OUTDOOR, audio_model

    print(f"\n🗂️ [STARTUP] BASE_DIR        = {BASE_DIR}")
    print(f"🗂️ [STARTUP] DEBUG_AUDIO_DIR = {DEBUG_AUDIO_DIR}")
    print(f"🗂️ [STARTUP] NEXTJS_URL      = {os.getenv('NEXTJS_URL', '(tidak diset, pakai default localhost:3000)')}\n")

    joblib_path = _resolve_model_path("deteksi_kondisi_4level_pipeline.joblib")
    if os.path.exists(joblib_path):
        try:
            bundle = joblib.load(joblib_path)
            condition_pipeline = bundle["model_pipeline"]
            kategori_bins = bundle["kategori_bins"]
            kategori_labels = bundle["kategori_labels"]
            DEFAULT_SUHU_MINIMAL_OUTDOOR = bundle.get("suhu_minimal_outdoor", 27.0)
        except Exception as exc:
            print(f"Gagal memuat condition pipeline: {exc}")

    audio_model = load_audio_model_safely()

    if audio_model is not None:
        try:
            dummy = np.zeros((1, IMG_SIZE, IMG_SIZE, 3), dtype=np.float32)
            audio_model.predict(dummy, verbose=0)
            print("🚀 [RIMBAREST AI System]: Model klasifikasi audio berjalan dengan sukses!")
        except Exception as exc:
            print(f"Audio model loaded, tapi warm-up gagal: {exc}")
    else:
        print("Audio model not loaded.")

    yield


app = FastAPI(title="RIMBAREST AI Server", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static-audio", StaticFiles(directory=DEBUG_AUDIO_DIR), name="static_audio")


def save_debug_audio(audio_bytes: bytes, prefix: str = "audio") -> str:
    if not audio_bytes or len(audio_bytes) < 100:
        return ""

    timestamp = datetime.datetime.utcnow().strftime("%Y%m%d_%H%M%S_%f")
    filename = f"{prefix}_{timestamp}.wav"
    path = os.path.join(DEBUG_AUDIO_DIR, filename)

    try:
        if audio_bytes[:4] == b'RIFF':
            with open(path, "wb") as f:
                f.write(audio_bytes)
            print(f"💾 [AUDIO DISK] File WAV utuh tersimpan: {filename} ({len(audio_bytes)} bytes)")
            return filename

        pcm_data = np.frombuffer(audio_bytes, dtype='<i2')
        with wave.open(path, "wb") as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(NATIVE_DEVICE_SR)
            wav_file.writeframes(pcm_data.tobytes())

        print(f"💾 [AUDIO DISK] Raw PCM berhasil dikemas ke WAV: {filename}")
        return filename
    except Exception as exc:
        print(f"❌ [AUDIO DISK ERROR] Gagal menyimpan file: {exc}")
        return ""


def _decode_audio_to_waveform(audio_bytes: bytes):
    """
    🔥 FIX UTAMA: baca sample rate ASLI dari header WAV kalau ada,
    jangan asumsi buta NATIVE_DEVICE_SR. Ini yang paling menentukan
    akurasi model, karena mel-spectrogram sangat sensitif terhadap SR yang salah.

    Return: (y: np.ndarray float32 mono, source_sr: int)
    """
    if audio_bytes[:4] == b'RIFF':
        try:
            # soundfile baca header WAV dengan benar: sample rate, channel, bit depth
            y, source_sr = sf.read(io.BytesIO(audio_bytes), dtype='float32', always_2d=False)
            if y.ndim > 1:
                y = np.mean(y, axis=1)  # ubah ke mono kalau stereo
            print(f"🎙️ [AUDIO INPUT] WAV header terbaca. SR asli: {source_sr}Hz, Sampel: {len(y)}")
            return y.astype(np.float32), source_sr
        except Exception as exc:
            print(f"⚠️ [AUDIO WARNING] Gagal baca via soundfile ({exc}), fallback ke parsing manual header WAV")
            # fallback: parse manual, tetap coba baca SR dari header, bukan asumsi
            with wave.open(io.BytesIO(audio_bytes), 'rb') as wf:
                source_sr = wf.getframerate()
                n_frames = wf.getnframes()
                raw = wf.readframes(n_frames)
            int16_samples = np.frombuffer(raw, dtype='<i2').astype(np.float32)
            y = int16_samples / 32768.0
            print(f"🎙️ [AUDIO INPUT] WAV parsed manual. SR asli: {source_sr}Hz, Sampel: {len(y)}")
            return y, source_sr

    # Bukan WAV (tidak ada RIFF header) → raw PCM murni dari device (MAX9814)
    # Di sinilah satu-satunya tempat yang SAH untuk pakai NATIVE_DEVICE_SR,
    # karena memang tidak ada metadata sample rate sama sekali.
    pcm_payload = audio_bytes
    if len(pcm_payload) % 2 != 0:
        pcm_payload = pcm_payload[:-1]
    int16_samples = np.frombuffer(pcm_payload, dtype='<i2').astype(np.float32)
    y = int16_samples / 32768.0
    print(f"🎙️ [AUDIO INPUT] Raw PCM tanpa header. Asumsi SR device: {NATIVE_DEVICE_SR}Hz, Sampel: {len(y)}")
    return y, NATIVE_DEVICE_SR


def proses_audio_from_bytes(audio_bytes: bytes) -> np.ndarray:
    import librosa
    import tensorflow as tf

    if not audio_bytes or len(audio_bytes) < 100:
        raise ValueError("Audio bytes kosong atau terlalu pendek")

    y, source_sr = _decode_audio_to_waveform(audio_bytes)

    if y is None or y.size == 0:
        raise RuntimeError("Gagal memproses gelombang data audio — hasil decode kosong")

    print(f"📈 [AUDIO STAT] RMS Amplitudo: {np.sqrt(np.mean(y ** 2)):.4f}")

    # 🔥 Resample ke SR target training, dari SR ASLI yang benar (bukan asumsi)
    if source_sr != SR:
        y = librosa.resample(y, orig_sr=source_sr, target_sr=SR)

    y = librosa.util.normalize(y)
    y = librosa.util.fix_length(y, size=DURATION_TARGET * SR)

    S = librosa.feature.melspectrogram(y=y, sr=SR, n_mels=N_MELS, fmax=FMAX)
    S_dB = librosa.power_to_db(S, ref=np.max)
    S_norm = (S_dB - S_dB.min()) / (S_dB.max() - S_dB.min() + 1e-8)

    S_resized = tf.image.resize(S_norm[..., np.newaxis], (IMG_SIZE, IMG_SIZE)).numpy()
    img_tensor = np.expand_dims(
        np.concatenate([S_resized, S_resized, S_resized], axis=-1), axis=0
    ).astype(np.float32)

    return img_tensor


def predict_audio_from_bytes(audio_bytes: bytes, noise_level: float = 52.0, saved_filename: str = ""):
    """
    🔥 PENTING: return value sekarang punya field ke-5 `is_model_prediction`
    supaya caller (dan kamu waktu debug) bisa BEDAKAN mana hasil AI asli
    vs mana yang cuma tebakan fallback berbasis noiseLevel.
    """
    if not saved_filename and audio_bytes is not None and len(audio_bytes) > 0:
        saved_filename = save_debug_audio(audio_bytes, "upload")
    saved_filename = saved_filename or ""

    if audio_bytes is None or len(audio_bytes) < 100:
        print("⚠️ [FALLBACK] Audio kosong/terlalu pendek — TIDAK memakai model AI, ini tebakan noiseLevel.")
        label = LABEL_SILENCE if noise_level <= 54.0 else LABEL_NEGATIF
        return label, 0.0, 0.0, saved_filename, False

    if audio_model is None:
        print("⚠️ [FALLBACK] Model AI belum ter-load — TIDAK memakai model AI, ini tebakan noiseLevel.")
        label = LABEL_SILENCE if noise_level <= 54.0 else LABEL_NEGATIF
        return label, 0.0, 0.0, saved_filename, False

    try:
        img_array = proses_audio_from_bytes(audio_bytes)

        print("🧠 [MODEL PREDICT] Memulai klasifikasi neural network DS-CNN (binary sigmoid)...")
        raw_output = audio_model.predict(img_array, verbose=0)
        raw_score = float(np.asarray(raw_output).reshape(-1)[0])

        is_positif = raw_score > THRESHOLD_POSITIF
        pred_class = CLASS_NAMES_BINARY[1] if is_positif else CLASS_NAMES_BINARY[0]
        confidence = raw_score if is_positif else (1.0 - raw_score)

        out_label = LABEL_POSITIF if is_positif else LABEL_NEGATIF

        print(f"📊 [SKOR MENTAH SIGMOID] {raw_score:.4f}  (0=negatif, 1=positif)")
        print(f"🔥 [AI RESULT DETECTED] Kelas: {pred_class.upper()} | Confidence: {confidence * 100:.2f}%")
        print(f"🏷️ [AI FINAL OUTPUT]   Label Terpilih   : {out_label}")

        return out_label, confidence, raw_score, saved_filename, True
    except Exception as err:
        print(f"❌ [AI PREDICT ERROR] Gagal mengklasifikasikan audio: {err}")
        print("⚠️ [FALLBACK] Terjadi error saat proses model — TIDAK memakai model AI, ini tebakan noiseLevel.")
        label = LABEL_SILENCE if noise_level <= 54.0 else LABEL_NEGATIF
        return label, 0.0, 0.0, saved_filename, False


# =====================================================================
# 🔥 EVALUASI KONDISI DENGAN PENGGABUNGAN HASIL AUDIO AI 🔥
# =====================================================================
def evaluate_air_condition(nodeCode: str, pm1: float, pm25: float, pm10: float, suhu: float, kelembapan: float, label_audio_ai: str = ""):
    if_score = 0.94
    preds = 1
    kat_asap = "Udara Bersih"
    status = "✅ Normal Bersih"

    if suhu > 60.0 or suhu < 0.0: suhu = 29.7
    if kelembapan > 100.0 or kelembapan < 0.0: kelembapan = 62.0

    if nodeCode not in NODE_DATA_BUFFER:
        NODE_DATA_BUFFER[nodeCode] = []
    NODE_DATA_BUFFER[nodeCode].append(pm25)
    if len(NODE_DATA_BUFFER[nodeCode]) > 5:
        NODE_DATA_BUFFER[nodeCode].pop(0)

    current_history = NODE_DATA_BUFFER[nodeCode]
    besar_data_count = sum(1 for x in current_history if x >= 190.0)

    # 1. Logika Sensor Partikulat (PM2.5)
    if pm25 >= 190.0:
        if besar_data_count >= 2:
            kat_asap = "Kebakaran Besar"
            status = "🚨 Kebakaran Besar"
            if_score = 0.98
        else:
            kat_asap = "Asap Tebal / Berpotensi Kebakaran Kecil-Sedang"
            status = "⚠️ Asap Tebal - Waspada"
            if_score = 0.85
    else:
        if pm25 > 50.0:
            kat_asap = "Polusi Udara / Debu / Asap Lokal"
            status = "⚠️ Polusi Tebal"
            if_score = 0.60
        else:
            kat_asap = "Udara Bersih"
            status = "✅ Normal Bersih"
            if_score = 0.32

    # 2. OVERRIDE/GABUNGKAN HASIL JIKA ADA ANCAMAN SUARA (AUDIO AI)
    is_audio_threat = (label_audio_ai == LABEL_POSITIF)
    if is_audio_threat:
        if "Kebakaran" in status:
            status = f"{status} + 🚨 Ancaman Suara"
        else:
            status = "🚨 Ancaman Suara Terdeteksi"

    is_anomaly = (pm25 >= 190.0) or is_audio_threat

    return {
        "if_score": if_score,
        "preds": preds,
        "kat_asap": kat_asap,
        "status": status,
        "is_anomaly": is_anomaly
    }


def _build_audio_url(audioUrl: str, chosen_file: str) -> str:
    fastapi_host = os.getenv("FASTAPI_PUBLIC_URL", "http://localhost:8000").rstrip('/')
    if chosen_file:
        clean_filename = os.path.basename(chosen_file)
        return f"{fastapi_host}/static-audio/{clean_filename}"

    if audioUrl and str(audioUrl).startswith(("http://", "https://")) and "local://" not in str(audioUrl) and "supabase.co" not in str(audioUrl):
        return audioUrl

    return None


@app.post("/predict-iot")
async def predict_iot(
    request: Request,
    background_tasks: BackgroundTasks = None,
    file: UploadFile = File(None),
    pm1: float = Form(0.0), pm25: float = Form(0.0), pm10: float = Form(0.0),
    suhu: float = Form(None), temperature: float = Form(None),
    kelembapan: float = Form(None), humidity: float = Form(None),
    noiseLevel: float = Form(52.0), nodeCode: str = Form("NODE-001"),
    readingId: str = Form(None),
    audioUrl: str = Form(None)
):
    audio_bytes = b""
    if file is not None:
        try:
            audio_bytes = bytes(await file.read())
        except Exception:
            pass

    if "application/json" in request.headers.get("content-type", ""):
        try:
            body = await request.json()
            pm1 = float(body.get("pm1", 0.0))
            pm25 = float(body.get("pm25", 0.0))
            pm10 = float(body.get("pm10", 0.0))
            suhu = float(body.get("suhu", body.get("temperature", 29.7)))
            kelembapan = float(body.get("kelembapan", body.get("humidity", 62.0)))
            nodeCode = str(body.get("nodeCode", "NODE-001"))
            readingId = body.get("readingId", readingId)
            audioUrl = body.get("audioUrl", None)
        except Exception:
            pass
    else:
        if suhu is None: suhu = temperature if temperature is not None else 29.7
        if kelembapan is None: kelembapan = humidity if humidity is not None else 62.0

    saved_fn = save_debug_audio(audio_bytes, prefix=f"incoming_{nodeCode}")

    try:
        final_audio_label, confidence_score_audio, raw_score, saved_fn, is_model_prediction = await asyncio.wait_for(
            asyncio.to_thread(predict_audio_from_bytes, audio_bytes, noiseLevel, saved_fn),
            timeout=FAST_PREDICT_TIMEOUT_SECONDS
        )
        air_result = evaluate_air_condition(nodeCode, pm1, pm25, pm10, suhu, kelembapan, final_audio_label)

        print(f"\n=======================================================")
        print(f"📡 [AI ENGINE LIVE] Node: {nodeCode} | Reading ID: {readingId}")
        print(f"📊 Fitur Input -> PM2.5: {pm25} µg/m³, Suhu: {suhu}°C, Humid: {kelembapan}%")
        print(f"🔊 Suara AI Output  -> Label: {final_audio_label} | Confidence: {confidence_score_audio * 100:.2f}% | Model dipakai: {is_model_prediction}")
        print(f"🧠 Status Terpadu   -> Hasil Keputusan Status: {air_result['status']}")
        print(f"=======================================================\n")

        fwd_args = (nodeCode, pm1, pm25, pm10, suhu, kelembapan, noiseLevel,
                    final_audio_label, confidence_score_audio, raw_score, air_result, audioUrl, saved_fn, readingId, is_model_prediction)

        if background_tasks is not None:
            background_tasks.add_task(_forward_result, *fwd_args)
        else:
            asyncio.create_task(_forward_result(*fwd_args))

        return JSONResponse({
            "status": "ok",
            "readingId": readingId,
            "aiLabelDetected": final_audio_label,
            "aiAudioScore": f"{confidence_score_audio * 100:.2f}%",
            "aiPartikulatScore": f"{air_result['if_score'] * 100:.2f}%",
            "aiStatusResult": air_result['status'],
            "kategoriAsap": air_result['kat_asap'],
            "isModelPrediction": is_model_prediction,  # 🔥 baru: transparansi ke Next.js/Flutter
        })

    except Exception as exc:
        print(f"⚠️ [AI TIMEOUT / ERROR] {exc}")
        air_result = evaluate_air_condition(nodeCode, pm1, pm25, pm10, suhu, kelembapan, LABEL_NEGATIF)

        fwd_args = (nodeCode, pm1, pm25, pm10, suhu, kelembapan, noiseLevel,
                    LABEL_NEGATIF, 0.0, 0.0, air_result, audioUrl, saved_fn, readingId, False)

        if background_tasks is not None:
            background_tasks.add_task(_forward_result, *fwd_args)
        else:
            asyncio.create_task(_forward_result(*fwd_args))

        return JSONResponse({
            "status": "accepted",
            "readingId": readingId,
            "aiLabelDetected": "Processing",
            "aiAudioScore": "0.00%",
            "aiPartikulatScore": f"{air_result['if_score'] * 100:.2f}%",
            "aiStatusResult": air_result['status'],
            "kategoriAsap": air_result['kat_asap'],
            "isModelPrediction": False,
        }, status_code=202)


async def _forward_result(nodeCode, pm1, pm25, pm10, suhu, kelembapan, noiseLevel,
                           final_audio_label, confidence_score_audio, raw_score, air_result, audioUrl, saved_filename, readingId=None, is_model_prediction=False):
    chosen_file = ""
    if saved_filename:
        chosen_file = os.path.basename(saved_filename)

    final_url = _build_audio_url(audioUrl, chosen_file)

    payload = {
        "nodeCode": nodeCode, "pm1": pm1, "pm25": pm25, "pm10": pm10, "suhu": suhu, "kelembapan": kelembapan,
        "noiseLevel": noiseLevel, "aiLabelDetected": final_audio_label, "aiDetectedAudioLabel": final_audio_label,
        "aiAudioScore": f"{confidence_score_audio * 100:.2f}%",
        "aiAudioPredictionScore": f"{confidence_score_audio * 100:.2f}%",
        "aiRawSigmoidScore": raw_score, "aiPartikulatScore": f"{air_result['if_score'] * 100:.2f}%",
        "aiPartikulatPredictionScore": f"{air_result['if_score'] * 100:.2f}%",
        "aiStatusResult": air_result['status'], "audioUrl": final_url, "kat_asap": air_result['kat_asap'],
        "aiKategoriAsap": air_result['kat_asap'],
        "readingId": readingId,
        "isModelPrediction": is_model_prediction,  # 🔥 diteruskan ke Next.js juga
    }

    urls_to_try = [
        os.getenv("NEXTJS_URL", "http://localhost:3000").rstrip('/'),
        "http://127.0.0.1:3000"
    ]

    for base_url in urls_to_try:
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                res = await client.post(f"{base_url}/api/iot/sensor", json=payload)
                if res.status_code == 200:
                    print(f"✅ [CALLBACK SUCCESS] Hasil AI sukses di-update ke Next.js ({base_url})")
                    break
        except Exception as err:
            print(f"⚠️ [CALLBACK RETRY] Gagal menghubungi {base_url}: {err}")


@app.post("/predict")
async def predict_audio_only(noiseLevel: float = Form(52.0), file: UploadFile = File(None)):
    if file is not None:
        audio_bytes = await file.read()
        label, confidence, raw_score, _, is_model_prediction = predict_audio_from_bytes(audio_bytes, noise_level=noiseLevel)
    else:
        label, confidence, raw_score, _, is_model_prediction = predict_audio_from_bytes(b"", noise_level=noiseLevel)
    return JSONResponse({
        "label": label,
        "predictionScore": confidence,
        "rawSigmoidScore": raw_score,
        "isModelPrediction": is_model_prediction,
        "status": "ok",
    })


@app.post("/evaluate-condition")
async def evaluate_condition(
    pm1: float = Form(0.0),
    pm25: float = Form(0.0),
    pm10: float = Form(0.0),
    suhu: float = Form(0.0),
    kelembapan: float = Form(0.0),
    label_audio_ai: str = Form("")
):
    result = evaluate_air_condition("GLOBAL_TEST", pm1, pm25, pm10, suhu, kelembapan, label_audio_ai)
    return JSONResponse({
        "status": result["status"],
        "kategoriAsap": result["kat_asap"],
        "isAnomaly": result["is_anomaly"],
        "isolationForestScore": result["if_score"],
    })


@app.get("/health")
def health():
    return {
        "status": "ok",
        "audio_model_loaded": audio_model is not None,
        "condition_pipeline_loaded": condition_pipeline is not None,
    }

@app.get('/labels')
def get_labels(): return JSONResponse({"labels": CLASS_NAMES_BINARY})