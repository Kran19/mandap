'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { z } from 'zod';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

const loginSchema = z.object({
  email: z.string().email({ message: 'Invalid email address' }),
  password: z.string().min(1, { message: 'Password is required' }),
});

type LoginValues = z.infer<typeof loginSchema>;

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  const form = useForm<LoginValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '', password: '' },
  });

  const onSubmit = async (values: LoginValues) => {
    setError(null);
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(values),
      });

      const data = await res.json();
      
      if (!res.ok) {
        setError(data.message || 'Login failed. Please check your credentials.');
        return;
      }

      router.push('/admin');
      router.refresh();
    } catch (err: any) {
      setError(err.message || 'An unexpected error occurred.');
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-950 relative overflow-hidden">
      {/* Background Gradient */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_left,_var(--tw-gradient-stops))] from-indigo-900/40 via-slate-900/80 to-slate-950"></div>
      
      {/* Glowing Orb */}
      <div className="absolute -top-[100px] -right-[100px] h-[300px] w-[300px] rounded-full bg-indigo-500/20 blur-[100px]"></div>

      <div className="relative w-full max-w-md space-y-8 rounded-3xl bg-white/5 p-10 shadow-[0_10px_30px_rgba(0,0,0,0.5)] backdrop-blur-xl border border-white/10 z-10">
        <div className="text-center">
          <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-indigo-500/20 mb-6">
             <svg className="h-6 w-6 text-indigo-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
               <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
             </svg>
          </div>
          <h2 className="mt-2 text-3xl font-bold tracking-tight text-white">
            Admin Portal
          </h2>
          <p className="mt-2 text-sm text-gray-400">
            Secure operations console
          </p>
        </div>

        <form className="mt-8 space-y-6" onSubmit={form.handleSubmit(onSubmit)}>
          {error && (
            <div className="rounded-lg bg-red-500/10 border border-red-500/30 p-4">
              <div className="flex items-center">
                <svg className="h-5 w-5 text-red-400 mr-3" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
                <p className="text-sm text-red-300">{error}</p>
              </div>
            </div>
          )}

          <div className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2" htmlFor="email">
                Email address
              </label>
              <input
                {...form.register('email')}
                id="email"
                type="email"
                autoComplete="email"
                className="block w-full appearance-none rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-white placeholder-gray-500 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 sm:text-sm transition-colors"
                placeholder="admin@example.com"
              />
              {form.formState.errors.email && (
                <p className="mt-2 text-sm text-red-400">
                  {form.formState.errors.email.message}
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2" htmlFor="password">
                Password
              </label>
              <input
                {...form.register('password')}
                id="password"
                type="password"
                autoComplete="current-password"
                className="block w-full appearance-none rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-white placeholder-gray-500 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 sm:text-sm transition-colors"
                placeholder="••••••••"
              />
              {form.formState.errors.password && (
                <p className="mt-2 text-sm text-red-400">
                  {form.formState.errors.password.message}
                </p>
              )}
            </div>
          </div>

          <div className="pt-2">
            <button
              type="submit"
              disabled={form.formState.isSubmitting}
              className="group relative flex w-full justify-center rounded-xl border border-transparent bg-gradient-to-r from-indigo-500 to-violet-500 py-3 px-4 text-sm font-semibold text-white shadow-lg hover:shadow-[0_4px_20px_rgba(139,92,246,0.4)] focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 focus:ring-offset-slate-900 disabled:opacity-50 transition-all duration-200"
            >
              {form.formState.isSubmitting ? (
                <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              ) : 'Sign in'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
