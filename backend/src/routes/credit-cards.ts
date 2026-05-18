import crypto from 'node:crypto';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { requireAuth, type AuthedRequest } from '../middleware/auth.js';
import {
  serializeCreditCard,
  serializeCreditScoreSnapshot,
} from '../utils/serializers.js';

export const creditCardsRouter = Router();

const creditCardSchema = z.object({
  id: z.string().trim().min(1).optional(),
  name: z.string().trim().min(1),
  lastFourDigits: z.string().trim().default(''),
  cardholderNameOverride: z.string().trim().nullable().optional(),
  isActive: z.boolean().default(true),
  limit: z.number().nonnegative(),
  availableLimit: z.number().nonnegative(),
  dueDay: z.number().int().min(1).max(31),
  statementDay: z.number().int().min(1).max(31),
  paymentGraceDays: z.number().int().min(0).max(90),
  colorHex: z.string().trim().min(1),
  shapeKey: z.string().trim().min(1),
  installments: z.array(z.any()).optional().default([]),
  futurePeriodPayments: z.array(z.any()).optional().default([]),
});

const scoreSnapshotSchema = z.object({
  id: z.string().trim().min(1).optional(),
  createdAt: z.string().datetime().optional(),
  score: z.number().int().min(0).max(100),
  totalLimit: z.number().nonnegative(),
  availableLimit: z.number().nonnegative(),
  currentStatementDebt: z.number().nonnegative(),
});

creditCardsRouter.use(requireAuth);

creditCardsRouter.get('/', async (req, res) => {
  const authedReq = req as AuthedRequest;
  const cards = await prisma.creditCard.findMany({
    where: { userId: authedReq.userId },
    orderBy: [{ isActive: 'desc' }, { updatedAt: 'desc' }],
  });

  return res.json(cards.map(serializeCreditCard));
});

creditCardsRouter.post('/', async (req, res) => {
  const authedReq = req as AuthedRequest;
  const input = creditCardSchema.parse(req.body);
  const cardId = input.id ?? `card_${crypto.randomUUID()}`;
  const existing = await prisma.creditCard.findUnique({ where: { id: cardId } });

  if (existing && existing.userId !== authedReq.userId) {
    return res.status(403).json({ message: 'Bu kart başka bir kullanıcıya ait' });
  }

  const payload = {
    name: input.name,
    lastFourDigits: input.lastFourDigits,
    cardholderNameOverride: input.cardholderNameOverride ?? null,
    isActive: input.isActive,
    limit: input.limit,
    availableLimit: input.availableLimit,
    dueDay: input.dueDay,
    statementDay: input.statementDay,
    paymentGraceDays: input.paymentGraceDays,
    colorHex: input.colorHex,
    shapeKey: input.shapeKey,
    installments: input.installments,
    futurePeriodPayments: input.futurePeriodPayments,
    userId: authedReq.userId,
  };

  const card = existing
    ? await prisma.creditCard.update({
        where: { id: cardId },
        data: payload,
      })
    : await prisma.creditCard.create({
        data: {
          id: cardId,
          ...payload,
        },
      });

  return res.status(existing ? 200 : 201).json(serializeCreditCard(card));
});

creditCardsRouter.delete('/:id', async (req, res) => {
  const authedReq = req as AuthedRequest;
  const card = await prisma.creditCard.findUnique({ where: { id: req.params.id } });

  if (!card || card.userId !== authedReq.userId) {
    return res.status(404).json({ message: 'Kart bulunamadı' });
  }

  await prisma.creditCard.delete({ where: { id: card.id } });
  return res.status(204).send();
});

creditCardsRouter.get('/score-history', async (req, res) => {
  const authedReq = req as AuthedRequest;
  const history = await prisma.creditScoreSnapshot.findMany({
    where: { userId: authedReq.userId },
    orderBy: { createdAt: 'desc' },
    take: 24,
  });

  return res.json(history.map(serializeCreditScoreSnapshot));
});

creditCardsRouter.post('/score-history', async (req, res) => {
  const authedReq = req as AuthedRequest;
  const input = scoreSnapshotSchema.parse(req.body);
  const snapshotId = input.id ?? `score_${crypto.randomUUID()}`;
  const existing = await prisma.creditScoreSnapshot.findUnique({
    where: { id: snapshotId },
  });

  if (existing && existing.userId !== authedReq.userId) {
    return res.status(403).json({ message: 'Bu skor kaydı başka bir kullanıcıya ait' });
  }

  const payload = {
    createdAt: input.createdAt ? new Date(input.createdAt) : new Date(),
    score: input.score,
    totalLimit: input.totalLimit,
    availableLimit: input.availableLimit,
    currentStatementDebt: input.currentStatementDebt,
    userId: authedReq.userId,
  };

  const snapshot = existing
    ? await prisma.creditScoreSnapshot.update({
        where: { id: snapshotId },
        data: payload,
      })
    : await prisma.creditScoreSnapshot.create({
        data: {
          id: snapshotId,
          ...payload,
        },
      });

  return res
    .status(existing ? 200 : 201)
    .json(serializeCreditScoreSnapshot(snapshot));
});
