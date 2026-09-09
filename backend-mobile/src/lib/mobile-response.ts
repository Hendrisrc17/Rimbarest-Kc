import { NextResponse } from 'next/server';

/**
 * 🌟 BARU — Helper response terstandarisasi khusus untuk endpoint mobile (Flutter).
 * Semua endpoint di app/api/mobile/** membalas dengan bentuk:
 * { success, message, data }
 * agar konsisten dengan AuthService / ApiService di sisi Flutter.
 * File ini murni tambahan baru, tidak mengubah response endpoint web/IoT yang sudah berjalan.
 */
export function mobileOk(data: any, message = 'OK', status = 200) {
  return NextResponse.json({ success: true, message, data }, { status });
}

export function mobileFail(message: string, status = 400, extra?: Record<string, any>) {
  return NextResponse.json({ success: false, message, ...(extra || {}) }, { status });
}
