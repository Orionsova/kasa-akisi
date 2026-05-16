import 'dotenv/config';
import { z } from 'zod';

const DEFAULT_GOOGLE_CLIENT_ID =
  '459972794493-kn3tk0ec16ll8chdi1q961lnde2270ro.apps.googleusercontent.com';

const envSchema = z.object({
  PORT: z.string().default('4000'),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(1),
  JWT_EXPIRES_IN: z.string().default('7d'),
  GOOGLE_CLIENT_ID: z.string().optional().default(DEFAULT_GOOGLE_CLIENT_ID),
  APPLE_AUDIENCE: z.string().optional().default(''),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment variables', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = {
  ...parsed.data,
  PORT: Number(parsed.data.PORT),
};
