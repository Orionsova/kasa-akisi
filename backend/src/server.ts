import { createApp } from './app.js';
import { env } from './config/env.js';
import { prisma } from './lib/prisma.js';
import { ensureSystemCategories } from './utils/system-categories.js';

async function bootstrap() {
  await prisma.$connect();
  await ensureSystemCategories();

  const app = createApp();
  app.listen(env.PORT, () => {
    console.log(`Kasa Akisi backend listening on http://localhost:${env.PORT}`);
  });
}

bootstrap().catch(async (error) => {
  console.error(error);
  await prisma.$disconnect();
  process.exit(1);
});
