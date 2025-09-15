import { z } from 'zod';
import { t } from './trpc';

export const appRouter = t.router({
  health: t.procedure.query(() => ({ status: 'ok' })),
  echo: t.procedure.input(z.object({ message: z.string() })).query(({ input }) => ({
    message: input.message,
  })),
});

export type AppRouter = typeof appRouter;

