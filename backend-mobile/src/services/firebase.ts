import { getApps, initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

// Cek jumlah app yang aktif menggunakan getApps() bawaan sub-module
const apps = getApps();

if (!apps.length) {
  try {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;

    if (serviceAccountJson) {
      // Opsi 1: satu JSON gabungan di FIREBASE_SERVICE_ACCOUNT
      const serviceAccount = JSON.parse(serviceAccountJson);
      initializeApp({
        credential: cert(serviceAccount),
      });
      console.log('Firebase Admin SDK sukses diinisialisasi (FIREBASE_SERVICE_ACCOUNT).');
    } else if (
      process.env.FIREBASE_PROJECT_ID &&
      process.env.FIREBASE_CLIENT_EMAIL &&
      process.env.FIREBASE_PRIVATE_KEY
    ) {
      // Opsi 2 (fallback): 3 variabel terpisah, seperti yang ada di .env saat ini
      initializeApp({
        credential: cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          // Private key di .env disimpan dengan literal "\n", perlu diubah jadi newline asli
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
      console.log('Firebase Admin SDK sukses diinisialisasi (FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY).');
    } else {
      console.warn('⚠️ Kredensial Firebase tidak ditemukan di .env (FIREBASE_SERVICE_ACCOUNT atau FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY).');
    }
  } catch (error) {
    console.error('Gagal menginisialisasi Firebase Admin SDK:', error);
  }
}

// Ambil instance messaging menggunakan getMessaging() terupdate
const messagingInstance = getApps().length ? getMessaging() : null;
export { messagingInstance as messaging };