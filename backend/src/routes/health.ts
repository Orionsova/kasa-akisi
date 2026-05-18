import { Router } from 'express';
import { prisma } from '../lib/prisma.js';

export const healthRouter = Router();

healthRouter.get('/', async (_req, res) => {
  await prisma.$queryRaw`SELECT 1`;
  return res.json({
    status: 'ok',
    service: 'kasa-akisi-backend',
    database: 'ok',
    timestamp: new Date().toISOString(),
  });
});
