"use client";
import { useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { createTRPCProxyClient, httpBatchLink } from '@trpc/client';
import type { AppRouter } from '@weekly-shopping/api';
import Link from 'next/link';

const queryClient = new QueryClient();
const client = createTRPCProxyClient<AppRouter>({
  links: [
    httpBatchLink({
      url: process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:4000/trpc',
    }),
  ],
});

export default function HomePage() {
  const [status, setStatus] = useState<string>('...');

  async function check() {
    const res = await client.health.query();
    setStatus(res.status);
  }

  return (
    <QueryClientProvider client={queryClient}>
      <main className="p-6">
        <h1 className="text-2xl font-semibold">Weekly Shopping</h1>
        <button
          className="mt-4 rounded bg-black px-4 py-2 text-white dark:bg-white dark:text-black"
          onClick={check}
        >
          Check API health
        </button>
        <p className="mt-2">API status: {status}</p>
        <div className="mt-6">
          <Link className="underline" href="/auth">Go to auth</Link>
        </div>
      </main>
    </QueryClientProvider>
  );
}

