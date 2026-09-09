'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Menu, LogOut, Settings } from 'lucide-react';
import { CurrentAdminUser } from '@/types';

interface HeaderProps {
  user: CurrentAdminUser | null;
  setSidebarOpen: (open: boolean) => void;
}

export default function Header({ user, setSidebarOpen }: HeaderProps) {
  const router = useRouter();

  const handleLogout = async () => {
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
    } catch (e) {
      console.error('Logout failed', e);
    } finally {
      router.push('/login');
      router.refresh();
    }
  };

  return (
    <header className="flex h-16 flex-shrink-0 items-center justify-between border-b border-gray-200 bg-white px-4 sm:px-6 lg:px-8 shadow-sm">
      <div className="flex items-center">
        <button
          type="button"
          className="mr-4 text-gray-500 hover:text-gray-700 sm:hidden"
          onClick={() => setSidebarOpen(true)}
        >
          <span className="sr-only">Open sidebar</span>
          <Menu className="h-6 w-6" aria-hidden="true" />
        </button>
        <h1 className="text-xl font-semibold text-gray-900 hidden sm:block">Admin Console</h1>
      </div>

      <div className="flex items-center space-x-4">
        {user && (
          <div className="flex items-center">
            <Link
              href="/admin/settings"
              className="flex items-center gap-1.5 text-sm font-medium text-gray-700 hover:text-blue-600 transition-colors mr-4"
              title="Account Settings"
            >
              <Settings className="w-4 h-4 text-gray-400" />
              <span>
                {user.firstName || user.lastName ? `${user.firstName || ''} ${user.lastName || ''}`.trim() : 'Admin'} ({user.email})
              </span>
            </Link>
          </div>
        )}
        <button
          onClick={handleLogout}
          className="flex items-center text-sm font-medium text-gray-500 hover:text-gray-700"
        >
          <LogOut className="h-4 w-4 mr-1" />
          Sign out
        </button>
      </div>
    </header>
  );
}
