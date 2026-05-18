import crypto from 'node:crypto';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { requireAuth, type AuthedRequest } from '../middleware/auth.js';
import { serializeInvestment } from '../utils/serializers.js';

export const investmentsRouter = Router();

const investmentSchema = z.object({
  id: z.string().trim().min(1).optional(),
  title: z.string().trim().min(1),
  type: z.string().trim().min(1),
  principal: z.number().nonnegative(),
  currentValue: z.number().nonnegative(),
  maturityRate: z.number().nullable().optional(),
  monthlyYield: z.number().nullable().optional(),
  termDays: z.number().int().positive().nullable().optional(),
  openedAt: z.string().datetime().nullable().optional(),
  symbol: z.string().trim().nullable().optional(),
  note: z.string().trim().nullable().optional(),
});

investmentsRouter.use(requireAuth);

investmentsRouter.get('/', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const items = await prisma.investment.findMany({
    where: { userId: authedReq.userId },
    orderBy: { updatedAt: 'desc' },
  });

  return res.json(items.map(serializeInvestment));
});

investmentsRouter.post('/', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const input = investmentSchema.parse(req.body);
  const investmentId = input.id ?? `inv_${crypto.randomUUID()}`;
  const existing = await prisma.investment.findUnique({
    where: { id: investmentId },
  });

  if (existing && existing.userId !== authedReq.userId) {
    return res.status(403).json({ message: 'Bu yatırım kaydı başka bir kullanıcıya ait' });
  }

  const payload = {
    title: input.title,
    type: input.type,
    principal: input.principal,
    currentValue: input.currentValue,
    maturityRate: input.maturityRate ?? null,
    monthlyYield: input.monthlyYield ?? null,
    termDays: input.termDays ?? null,
    openedAt: input.openedAt == null ? null : new Date(input.openedAt),
    symbol: input.symbol ?? null,
    note: input.note ?? null,
    userId: authedReq.userId,
  };

  const investment = existing
    ? await prisma.investment.update({
        where: { id: investmentId },
        data: payload,
      })
    : await prisma.investment.create({
        data: {
          id: investmentId,
          ...payload,
        },
      });

  return res.status(existing ? 200 : 201).json(serializeInvestment(investment));
});

investmentsRouter.delete('/:id', async (req, res) => {
  const authedReq = req as unknown as AuthedRequest;
  const item = await prisma.investment.findUnique({ where: { id: req.params.id } });

  if (!item || item.userId !== authedReq.userId) {
    return res.status(404).json({ message: 'Yatırım bulunamadı' });
  }

  await prisma.investment.delete({ where: { id: item.id } });
  return res.status(204).send();
});
