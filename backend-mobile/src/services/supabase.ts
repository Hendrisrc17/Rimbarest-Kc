import { createClient } from '@supabase/supabase-js';

const KNOWN_GOOD_SUPABASE_URL = 'https://janhedeadieuyxmfiiok.supabase.co';

const supabaseUrl = process.env.SUPABASE_URL || KNOWN_GOOD_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY || 'your-service-role-key';

// 🚀 VALIDASI STARTUP: teriak jelas di log kalau env var kelihatan salah/placeholder,
// supaya ketahuan LANGSUNG saat server start, bukan nanti pas user gagal main audio
// di HP dan errornya cuma "Failed host lookup" yang membingungkan.
function validateSupabaseConfig() {
  const problems: string[] = [];

  if (!/^https:\/\/[a-z0-9]+\.supabase\.co$/i.test(supabaseUrl)) {
    problems.push(
      `SUPABASE_URL ("${supabaseUrl}") tidak terlihat seperti Project URL Supabase yang valid ` +
      `(format seharusnya https://<random-hash>.supabase.co). Cek env var SUPABASE_URL di .env, ` +
      `bandingkan dengan Settings > API > Project URL di dashboard Supabase kamu.`
    );
  }

  if (!supabaseKey || supabaseKey === 'your-service-role-key') {
    problems.push(
      `SUPABASE_SERVICE_ROLE_KEY / SUPABASE_KEY belum di-set (masih pakai placeholder). ` +
      `Upload audio ke Supabase Storage akan GAGAL (401) sampai ini diisi dengan service role key asli.`
    );
  }

  if (problems.length > 0) {
    console.error('🚨 [Supabase Config] Ditemukan masalah konfigurasi:');
    problems.forEach((p) => console.error(`   - ${p}`));
  } else {
    console.log(`✅ [Supabase Config] URL & key terlihat valid (${supabaseUrl}).`);
  }
}

validateSupabaseConfig();

// Menggunakan service role key agar bypass Row Level Security (RLS) saat upload file dari server
export const supabase = createClient(supabaseUrl, supabaseKey);

export default supabase;