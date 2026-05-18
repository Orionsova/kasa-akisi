import crypto from 'node:crypto';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { requireAuth, type AuthedRequest } from '../middleware/auth.js';
import { serializeRecurringTransaction } from '../utils/serializers.js';

export const recurringTransactionsRouter = Router();

const recurringSchema = z.object({
  id: z.string().trim().min(1).optional(),
  title: z.string().trim().min(1),
  category: z.string().trim().min(1),
  amount: z.number().nonnegative(),
  dayOfMonth: z.number().int().min(1).max(31),
  isIncome: z.boolean(),
  isSubscription: z.boolean().optional().default(false),
  note: z.string().trim().nullable().optional(),
  startDate: z.string().datetime(),
});

recurringTransactionsRouter.use(requireAuth);

recurringTransactionsRouter.get('/', async (req, res) => {
  const authedReq = req as AuthedRequest;
  const items = await prisma.recurringTransaction.findMany({
    where: { userId: authedReq.userId },
    orderBy: [{ dayOfMonth: 'asc' }, { updatedAt: 'desc' }],
  });

  return res.json(items.map(serializeRecurringTransaction));
});

recurringTransactionsRouter.post('/', async (req, res) => {
  const authedReq = req as AuthedRequest;
  const input = recurringSchema.parse(req.body);
  const itemId = input.id ?? `rec_${crypto.randomUUID()}`;
  const existing = await prisma.recurringTransaction.findUnique({
    where: { id: itemId },
  });

  if (existing && existing.userId !== authedReq.userId) {
    return res
      .status(403)
      .json({ message: 'Bu düzenli işlem başka bir kullanıcıya ait' });
  }

  const payload = {
    title: input.title,
    category: input.category,
    amount: input.amount,
    dayOfMonth: input.dayOfMonth,
    isIncome: input.isIncome,
    isSubscription: input.isSubscription,
    note: input.note ?? null,
    startDate: new Date(input.startDate),
    userId: authedReq.userId,
  };

  const item = existing
    ? await prisma.recurringTransaction.update({
        where: { id: itemId },
        data: payload,
      })
    : await prisma.recurringTransaction.create({
        data: {
          id: itemId,
          ...payload,
        },
      });

  return res.status(existing ? 200 : 201).json(serializeRecurringTransaction(item));
});

recurringTransactionsRouter.delete('/:id', async (req, res) => {
  const authedReq = req as AuthedRequest;
  const item = await prisma.recurringTransaction.findUnique({
    where: { id: req.params.id },
  });

  if (!item || item.userId !== authedReq.userId) {
    return res.status(404).json({ message: 'Düzenli işlem bulunamadı' });
  }

  await prisma.recurringTransaction.delete({ where: { id: item.id } });
  return res.status(204).send();
});
