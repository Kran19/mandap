'use client';

import React, { useState } from 'react';
import { CurrentAdminUser } from '@/types';
import Sidebar from './Sidebar';
import Header from './Header';

interface AdminShellProps {
  user: CurrentAdminUser | null;
  children: React.ReactNode;
}

export default function AdminShell({ user, children }: AdminShellProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <>
      <Sidebar user={user} open={sidebarOpen} setOpen={setSidebarOpen} />
      
      <div className="flex flex-1 flex-col overflow-hidden">
        <Header user={user} setSidebarOpen={setSidebarOpen} />
        
        <main className="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8">
          <div className="mx-auto max-w-7xl">
            {children}
          </div>
        </main>
      </div>
    </>
  );
}
