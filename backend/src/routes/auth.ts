import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { comparePassword, hashPassword, signAccessToken } from '../lib/auth.js';
import { requireAuth, type AuthedRequest } from '../middleware/auth.js';
import { serializeUser } from '../utils/serializers.js';
import { verifyGoogleIdToken } from '../lib/google.js';

export const authRouter = Router();

const passwordSchema = z
  .string()
  .min(8, 'Şifre en az 8 karakter olmalı')
  .regex(/[A-Z]/, 'Şifre en az bir büyük harf içermeli')
  .regex(/[a-z]/, 'Şifre en az bir küçük harf içermeli');

const registerSchema = z.object({
  email: z.string().email(),
  password: passwordSchema,
  firstName: z.string().trim().optional(),
  lastName: z.string().trim().optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

const googleSchema = z.object({
  idToken: z.string().min(1),
});

authRouter.post('/register', async (req, res) => {
  const input = registerSchema.parse(req.body);

  const existingUser = await prisma.user.findUnique({
    where: { email: input.email.toLowerCase() },
  });

  if (existingUser) {
    return res.status(409).json({ message: 'Bu e-posta zaten kayıtlı' });
  }

  const user = await prisma.user.create({
    data: {
      email: input.email.toLowerCase(),
      passwordHash: await hashPassword(input.password),
      firstName: input.firstName,
      lastName: input.lastName,
      provider: 'email',
    },
  });

  const token = signAccessToken({ sub: user.id, email: user.email });
  return res.status(201).json({ token, user: serializeUser(user) });
});

authRouter.post('/login', async (req, res) => {
  const input = loginSchema.parse(req.body);
  const user = await prisma.user.findUnique({
    where: { email: input.email.toLowerCase() },
  });

  if (!user?.passwordHash) {
    return res.status(401).json({ message: 'Geçersiz giriş bilgileri' });
  }

  const isValid = await comparePassword(input.password, user.passwordHash);
  if (!isValid) {
    return res.status(401).json({ message: 'Geçersiz giriş bilgileri' });
  }

  const token = signAccessToken({ sub: user.id, email: user.email });
  return res.json({ token, user: serializeUser(user) });
});

authRouter.post('/google', async (req, res) => {
  const input = googleSchema.parse(req.body);
  const googleUser = await verifyGoogleIdToken(input.idToken);

  const user = await prisma.user.upsert({
    where: { email: googleUser.email.toLowerCase() },
    update: {
      firstName: googleUser.firstName || undefined,
      lastName: googleUser.lastName || undefined,
      profilePhoto: googleUser.profilePhoto || undefined,
      provider: 'google',
      providerUserId: googleUser.providerUserId,
    },
    create: {
      email: googleUser.email.toLowerCase(),
      firstName: googleUser.firstName,
      lastName: googleUser.lastName,
      profilePhoto: googleUser.profilePhoto,
      provider: 'google',
      providerUserId: googleUser.providerUserId,
    },
  });

  const token = signAccessToken({ sub: user.id, email: user.email });
  return res.json({ token, user: serializeUser(user) });
});

authRouter.post('/apple', async (_req, res) => {
  return res.status(501).json({
    message: 'Apple Sign In altyapısı için route hazır. Token doğrulama entegrasyonu eklenmeli.',
  });
});

authRouter.get('/profile', requireAuth, async (req, res) => {
  const authedReq = req as AuthedRequest;
  const user = await prisma.user.findUniqueOrThrow({
    where: { id: authedReq.userId },
  });
  return res.json(serializeUser(user));
});
