import { Router } from 'express';

export const healthRouter = Router();

healthRouter.get('/', (_req, res) => {
  return res.json({
    status: 'ok',
    service: 'kasa-akisi-backend',
    timestamp: new Date().toISOString(),
  });
});
