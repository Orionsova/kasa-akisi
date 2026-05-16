import type { NextFunction, Request, Response } from 'express';
import { prisma } from '../lib/prisma.js';
import { verifyAccessToken } from '../lib/auth.js';

export type AuthedRequest = Request & {
  userId: string;
  userEmail: string;
};

export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const token = authHeader.replace('Bearer ', '');
    const payload = verifyAccessToken(token);
    const user = await prisma.user.findUnique({ where: { id: payload.sub } });

    if (!user) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    (req as AuthedRequest).userId = user.id;
    (req as AuthedRequest).userEmail = user.email;
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Unauthorized' });
  }
}
