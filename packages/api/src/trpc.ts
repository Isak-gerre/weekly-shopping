import { initTRPC } from '@trpc/server';

export const t = initTRPC.context<{
  supabase: unknown | null;
}>().create();

