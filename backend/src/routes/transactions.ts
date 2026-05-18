import crypto from 'node:crypto';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { requireAuth, type AuthedRequest } from '../middleware/auth.js';
import { serializeTransaction } from '../utils/serializers.js';

export const transactionsRouter = Router();

const transactionSchema = z.object({
  id: z.string().trim().min(1).optional(),
  title: z.string().trim().min(1),
  description: z.string().trim().nullable().optional(),
  amount: z.number().positive(),
  category: z.string().trim().min(1),
  date: z.string().datetime(),
  isIncome: z.boolean(),
  selectedCardId: z.string().trim().nullable().optional(),
  isInstallment: z.boolean().optional().default(false),
  transactionType: z.string().trim().min(1).optional().default('standard'),
});

transactionsRouter.use(requireAuth);

transactionsRouter.get('/', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const transactions = await prisma.transaction.findMany({
    where: { userId: authedReq.userId },
    orderBy: { date: 'desc' },
  });

  return res.json(transactions.map(serializeTransaction));
});

transactionsRouter.post('/', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const input = transactionSchema.parse(req.body);
  const transactionId = input.id ?? `txn_${crypto.randomUUID()}`;
  const existing = await prisma.transaction.findUnique({
    where: { id: transactionId },
  });

  if (existing && existing.userId !== authedReq.userId) {
    return res.status(403).json({ message: 'Bu işlem kaydı başka bir kullanıcıya ait' });
  }

  const payload = {
    title: input.title,
    description: input.description ?? null,
    amount: input.amount,
    category: input.category,
    date: new Date(input.date),
    isIncome: input.isIncome,
    selectedCardId: input.selectedCardId ?? null,
    isInstallment: input.isInstallment,
    transactionType: input.transactionType,
    userId: authedReq.userId,
  };

  const transaction = existing
    ? await prisma.transaction.update({
        where: { id: transactionId },
        data: payload,
      })
    : await prisma.transaction.create({
        data: {
          id: transactionId,
          ...payload,
        },
      });

  return res.status(201).json({
    transaction: serializeTransaction(transaction),
  });
});

transactionsRouter.delete('/:id', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const transaction = await prisma.transaction.findUnique({
    where: { id: req.params.id },
  });

  if (!transaction || transaction.userId !== authedReq.userId) {
    return res.status(404).json({ message: 'İşlem bulunamadı' });
  }

  await prisma.transaction.delete({ where: { id: transaction.id } });
  return res.status(204).send();
});
