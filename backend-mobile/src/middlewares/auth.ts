import { NextRequest } from 'next/server';
import { verifyToken } from '@/lib/jwt';

export interface AuthenticatedRequest extends NextRequest {
  user?: {
    id: string;
    username: string;
    role: string;
  };
}

/**
 * Helper middleware untuk mengecek JWT dari header Authorization
 */
export function checkAuth(req: AuthenticatedRequest): boolean {
  try {
    const authHeader = req.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) return false;

    const token = authHeader.split(' ')[1];
    const decoded = verifyToken(token);

    if (!decoded) return false;

    // Menyisipkan data user yang terverifikasi ke dalam objek request
    req.user = decoded;
    return true;
  } catch (error) {
    return false;
  }
}