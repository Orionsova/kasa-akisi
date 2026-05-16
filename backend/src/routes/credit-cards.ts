import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { requireAuth, type AuthedRequest } from '../middleware/auth.js';
import {
  serializeCreditCard,
  serializeCreditScoreSnapshot,
} from '../utils/serializers.js';

const installmentSchema = z.object({
  id: z.string().min(1),
  title: z.string().min(1),
  totalAmount: z.number(),
  monthlyAmount: z.number(),
  totalInstallments: z.number().int().min(1),
  remainingInstallments: z.number().int().min(0),
  firstPaymentDate: z.string().datetime(),
});

const futurePaymentSchema = z.object({
  id: z.string().min(1),
  title: z.string().min(1),
  monthLabel: z.string().min(1),
  amount: z.number(),
  totalInstallments: z.number().int().nullable().optional(),
  remainingInstallments: z.number().int().nullable().optional(),
});

const cardSchema = z.object({
  id: z.string().min(1),
  name: z.string().trim().min(1),
  lastFourDigits: z.string().optional().default(''),
  cardholderNameOverride: z.string().trim().nullable().optional(),
  isActive: z.boolean().default(true),
  limit: z.number().nonnegative(),
  availableLimit: z.number().nonnegative(),
  dueDay: z.number().int().min(1).max(31),
  statementDay: z.number().int().min(1).max(31),
  paymentGraceDays: z.number().int().min(1).max(60).default(10),
  colorHex: z.string().default('graphite_metal'),
  shapeKey: z.string().default('diagonal_gloss'),
  installments: z.array(installmentSchema).default([]),
  futurePeriodPayments: z.array(futurePaymentSchema).default([]),
});

const creditScoreSchema = z.object({
  id: z.string().min(1),
  score: z.number().int().min(0).max(100),
  totalLimit: z.number().nonnegative(),
  availableLimit: z.number().nonnegative(),
  currentStatementDebt: z.number().nonnegative(),
  createdAt: z.string().datetime().optional(),
});

export const creditCardsRouter = Router();
creditCardsRouter.use(requireAuth);

creditCardsRouter.get('/', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const cards = await prisma.creditCard.findMany({
    where: { userId: authedReq.userId },
    orderBy: [{ isActive: 'desc' }, { createdAt: 'desc' }],
  });

  return res.json(cards.map(serializeCreditCard));
});

creditCardsRouter.post('/', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const input = cardSchema.parse(req.body);

  const card = await prisma.creditCard.upsert({
    where: { id: input.id },
    update: {
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
    },
    create: {
      id: input.id,
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
    },
  });

  return res.status(201).json(serializeCreditCard(card));
});

creditCardsRouter.delete('/:id', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const card = await prisma.creditCard.findUnique({
    where: { id: req.params.id },
  });
  if (!card || card.userId !== authedReq.userId) {
    return res.status(404).json({ message: 'Kart bulunamadı' });
  }

  await prisma.creditCard.delete({ where: { id: card.id } });
  return res.status(204).send();
});

creditCardsRouter.get('/score-history', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const items = await prisma.creditScoreSnapshot.findMany({
    where: { userId: authedReq.userId },
    orderBy: { createdAt: 'desc' },
    take: 24,
  });
  return res.json(items.map(serializeCreditScoreSnapshot));
});

creditCardsRouter.post('/score-history', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const input = creditScoreSchema.parse(req.body);

  const item = await prisma.creditScoreSnapshot.upsert({
    where: { id: input.id },
    update: {
      score: input.score,
      totalLimit: input.totalLimit,
      availableLimit: input.availableLimit,
      currentStatementDebt: input.currentStatementDebt,
    },
    create: {
      id: input.id,
      score: input.score,
      totalLimit: input.totalLimit,
      availableLimit: input.availableLimit,
      currentStatementDebt: input.currentStatementDebt,
      createdAt: input.createdAt ? new Date(input.createdAt) : new Date(),
      userId: authedReq.userId,
    },
  });

  return res.status(201).json(serializeCreditScoreSnapshot(item));
});
