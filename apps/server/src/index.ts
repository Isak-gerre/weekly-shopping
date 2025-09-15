import Fastify from 'fastify';
import cors from '@fastify/cors';
import { fastifyTRPCPlugin } from '@trpc/server/adapters/fastify';
import { createClient } from '@supabase/supabase-js';
import { appRouter } from '@weekly-shopping/api';

const env = {
  NODE_ENV: process.env.NODE_ENV ?? 'development',
  PORT: Number(process.env.PORT ?? 4000),
  SUPABASE_URL: process.env.SUPABASE_URL ?? '',
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY ?? '',
};

if (!env.SUPABASE_URL || !env.SUPABASE_ANON_KEY) {
  // eslint-disable-next-line no-console
  console.warn('SUPABASE_URL or SUPABASE_ANON_KEY is not set. Supabase client will not be available.');
}

export const supabase = env.SUPABASE_URL && env.SUPABASE_ANON_KEY
  ? createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY)
  : null;

export type { AppRouter } from '@weekly-shopping/api';

async function main() {
  const fastify = Fastify({ logger: true });
  await fastify.register(cors, { origin: true });

  await fastify.register(fastifyTRPCPlugin, {
    prefix: '/trpc',
    trpcOptions: { router: appRouter, createContext: () => ({ supabase }) },
  });

  fastify.get('/healthz', async () => ({ status: 'ok' }));

  await fastify.listen({ port: env.PORT, host: '0.0.0.0' });
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});


