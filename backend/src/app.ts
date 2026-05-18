import cors from 'cors';
import express from 'express';
import { authRouter } from './routes/auth.js';
import { categoriesRouter } from './routes/categories.js';
import { creditCardsRouter } from './routes/credit-cards.js';
import { investmentsRouter } from './routes/investments.js';
import { marketRouter } from './routes/market.js';
import { recurringTransactionsRouter } from './routes/recurring-transactions.js';
import { transactionsRouter } from './routes/transactions.js';
import { healthRouter } from './routes/health.js';
import { errorHandler, notFoundHandler } from './middleware/error.js';

export function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get('/api', (_req, res) => {
    return res.json({ service: 'kasa-akisi-backend', status: 'ok' });
  });

  app.use('/api/health', healthRouter);
  app.use('/api/market', marketRouter);
  app.use('/api/auth', authRouter);
  app.use('/api/categories', categoriesRouter);
  app.use('/api/transactions', transactionsRouter);
  app.use('/api/credit-cards', creditCardsRouter);
  app.use('/api/investments', investmentsRouter);
  app.use('/api/recurring-transactions', recurringTransactionsRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
