import { NextResponse } from 'next/server';
import { sendPushNotification } from '@/services/notification';

export async function GET() {
  await sendPushNotification(
    "🚨 TESTING DARURAT PKM",
    "Jika lu membaca ini sambil nonton YouTube, berarti SISTEM SUDAH FIX BANTAH EMAS!"
  );
  return NextResponse.json({ message: "Test push terkirim ke fungsi Firebase" });
}