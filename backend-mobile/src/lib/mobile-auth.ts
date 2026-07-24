// File: src/lib/mobile-auth.ts
import { NextRequest } from 'next/server';
import { verifyToken } from './jwt';

export interface MobileAuthUser {
  id: string;
  username: string;
  role: string;
}

/**
 * 🌟 Helper otentikasi khusus endpoint mobile.
 * Membaca header "Authorization: Bearer <token>" dan mengembalikan payload JWT
 * ({ id, username, role }) atau null jika tidak valid/kosong.
 */
export function getMobileAuthUser(req: NextRequest): MobileAuthUser | null {
  try {
    const authHeader = req.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) return null;

    const token = authHeader.split(' ')[1];
    if (!token) return null;

    const decoded = verifyToken(token);
    return decoded as MobileAuthUser | null;
  } catch (error) {
    return null;
  }
}