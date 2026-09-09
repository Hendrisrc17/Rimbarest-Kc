import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_rimbarest_key_2026';

interface JwtPayload {
  id: string;
  username: string;
  role: string;
}

export function signToken(payload: JwtPayload): string {
  // Token berlaku selama 30 hari agar user mobile tidak sering ter-logout otomatis
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '30d' });
}

export function verifyToken(token: string): JwtPayload | null {
  try {
    return jwt.verify(token, JWT_SECRET) as JwtPayload;
  } catch (error) {
    return null;
  }
}