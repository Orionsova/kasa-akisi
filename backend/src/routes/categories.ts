import { Router } from 'express';
import { CategoryType } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '../lib/prisma.js';
import { requireAuth, type AuthedRequest } from '../middleware/auth.js';
import { serializeCategory } from '../utils/serializers.js';
import { ensureSystemCategories } from '../utils/system-categories.js';

export const categoriesRouter = Router();

const categorySchema = z.object({
  name: z.string().trim().min(1),
  type: z.nativeEnum(CategoryType),
  icon: z.string().trim().optional(),
});

categoriesRouter.use(requireAuth);

categoriesRouter.get('/', async (req, res) => {
  await ensureSystemCategories();
  const authedReq = req as AuthedRequest;

  const categories = await prisma.category.findMany({
    where: {
      OR: [{ isSystem: true }, { userId: authedReq.userId }],
    },
    orderBy: [{ isSystem: 'desc' }, { name: 'asc' }],
  });

  return res.json(categories.map(serializeCategory));
});

categoriesRouter.post('/', async (req, res) => {
  const authedReq = req as AuthedRequest;
  const input = categorySchema.parse(req.body);

  const category = await prisma.category.create({
    data: {
      name: input.name,
      type: input.type,
      icon: input.icon,
      userId: authedReq.userId,
      isSystem: false,
    },
  });

  return res.status(201).json(serializeCategory(category));
});

categoriesRouter.put('/:id', async (req, res) => {
  const authedReq = req as AuthedRequest;
  const input = categorySchema.parse(req.body);

  const category = await prisma.category.findUnique({
    where: { id: req.params.id },
  });

  if (!category || category.userId !== authedReq.userId || category.isSystem) {
    return res.status(404).json({ message: 'Kategori bulunamadı' });
  }

  const updated = await prisma.category.update({
    where: { id: category.id },
    data: {
      name: input.name,
      type: input.type,
      icon: input.icon,
    },
  });

  return res.json(serializeCategory(updated));
});

categoriesRouter.delete('/:id', async (req, res) => {
  const authedReq = req as AuthedRequest;

  const category = await prisma.category.findUnique({
    where: { id: req.params.id },
  });

  if (!category || category.userId !== authedReq.userId || category.isSystem) {
    return res.status(404).json({ message: 'Kategori bulunamadı' });
  }

  await prisma.category.delete({ where: { id: category.id } });
  return res.status(204).send();
});
