import './globals.css';
import { ThemeProvider } from 'next-themes';
import type { ReactNode } from 'react';
import { ThemeToggle } from '../components/theme-toggle';

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          <div className="flex min-h-dvh flex-col">
            <header className="flex items-center justify-between border-b px-6 py-3">
              <div className="font-semibold">Weekly Shopping</div>
              <ThemeToggle />
            </header>
            <div className="flex-1">{children}</div>
          </div>
        </ThemeProvider>
      </body>
    </html>
  );
}

