import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { requireAuth, type AuthedRequest } from '../middleware/auth.js';
import { serializeInvestment } from '../utils/serializers.js';

const investmentSchema = z.object({
  id: z.string().min(1),
  title: z.string().trim().min(1),
  type: z.string().trim().min(1),
  principal: z.number().nonnegative(),
  currentValue: z.number().nonnegative(),
  maturityRate: z.number().nullable().optional(),
  monthlyYield: z.number().nullable().optional(),
  symbol: z.string().trim().nullable().optional(),
  note: z.string().trim().nullable().optional(),
});

export const investmentsRouter = Router();
investmentsRouter.use(requireAuth);

investmentsRouter.get('/', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const items = await prisma.investment.findMany({
    where: { userId: authedReq.userId },
    orderBy: { createdAt: 'desc' },
  });
  return res.json(items.map(serializeInvestment));
});

investmentsRouter.post('/', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const input = investmentSchema.parse(req.body);

  const item = await prisma.investment.upsert({
    where: { id: input.id },
    update: {
      title: input.title,
      type: input.type,
      principal: input.principal,
      currentValue: input.currentValue,
      maturityRate: input.maturityRate ?? null,
      monthlyYield: input.monthlyYield ?? null,
      symbol: input.symbol ?? null,
      note: input.note ?? null,
      userId: authedReq.userId,
    },
    create: {
      id: input.id,
      title: input.title,
      type: input.type,
      principal: input.principal,
      currentValue: input.currentValue,
      maturityRate: input.maturityRate ?? null,
      monthlyYield: input.monthlyYield ?? null,
      symbol: input.symbol ?? null,
      note: input.note ?? null,
      userId: authedReq.userId,
    },
  });

  return res.status(201).json(serializeInvestment(item));
});

investmentsRouter.delete('/:id', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const item = await prisma.investment.findUnique({
    where: { id: req.params.id },
  });
  if (!item || item.userId !== authedReq.userId) {
    return res.status(404).json({ message: 'Yatırım bulunamadı' });
  }

  await prisma.investment.delete({ where: { id: item.id } });
  return res.status(204).send();
});
