import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { requireAuth, type AuthedRequest } from '../middleware/auth.js';
import { serializeRecurringTransaction } from '../utils/serializers.js';

const recurringSchema = z.object({
  id: z.string().min(1),
  title: z.string().trim().min(1),
  category: z.string().trim().min(1),
  amount: z.number().nonnegative(),
  dayOfMonth: z.number().int().min(1).max(31),
  isIncome: z.boolean(),
  isSubscription: z.boolean(),
  note: z.string().trim().nullable().optional(),
  startDate: z.string().datetime(),
});

export const recurringTransactionsRouter = Router();
recurringTransactionsRouter.use(requireAuth);

recurringTransactionsRouter.get('/', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const items = await prisma.recurringTransaction.findMany({
    where: { userId: authedReq.userId },
    orderBy: [{ dayOfMonth: 'asc' }, { createdAt: 'desc' }],
  });
  return res.json(items.map(serializeRecurringTransaction));
});

recurringTransactionsRouter.post('/', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const input = recurringSchema.parse(req.body);

  const item = await prisma.recurringTransaction.upsert({
    where: { id: input.id },
    update: {
      title: input.title,
      category: input.category,
      amount: input.amount,
      dayOfMonth: input.dayOfMonth,
      isIncome: input.isIncome,
      isSubscription: input.isSubscription,
      note: input.note ?? null,
      startDate: new Date(input.startDate),
      userId: authedReq.userId,
    },
    create: {
      id: input.id,
      title: input.title,
      category: input.category,
      amount: input.amount,
      dayOfMonth: input.dayOfMonth,
      isIncome: input.isIncome,
      isSubscription: input.isSubscription,
      note: input.note ?? null,
      startDate: new Date(input.startDate),
      userId: authedReq.userId,
    },
  });

  return res.status(201).json(serializeRecurringTransaction(item));
});

recurringTransactionsRouter.delete('/:id', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const item = await prisma.recurringTransaction.findUnique({
    where: { id: req.params.id },
  });
  if (!item || item.userId !== authedReq.userId) {
    return res.status(404).json({ message: 'Düzenli kayıt bulunamadı' });
  }

  await prisma.recurringTransaction.delete({ where: { id: item.id } });
  return res.status(204).send();
});
