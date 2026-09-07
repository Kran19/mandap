'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { User } from '@/types';
import { updateUserStatus } from './actions';

export default function UserActions({ user }: { user: User }) {
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isActive = user.status === 'ACTIVE';

  const handleToggleStatus = async () => {
    const newStatus = isActive ? 'SUSPENDED' : 'ACTIVE';
    const confirmMessage = isActive
      ? `Are you sure you want to suspend this user? Their active sessions will be terminated.`
      : `Are you sure you want to activate this user?`;

    if (!window.confirm(confirmMessage)) return;

    setIsSubmitting(true);
    setError(null);
    try {
      const res = await updateUserStatus(user.id, newStatus);
      if (res.error) {
        setError(res.error);
      } else {
        router.refresh();
      }
    } catch (e: any) {
      setError(e.message || 'An unexpected error occurred.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="flex items-center gap-4">
      {error && <span className="text-sm text-red-600">{error}</span>}
      <button
        onClick={handleToggleStatus}
        disabled={isSubmitting}
        className={`rounded-md px-3 py-2 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 disabled:opacity-50 ${
          isActive 
            ? 'bg-red-600 hover:bg-red-500 focus-visible:outline-red-600' 
            : 'bg-green-600 hover:bg-green-500 focus-visible:outline-green-600'
        }`}
      >
        {isSubmitting ? 'Processing...' : isActive ? 'Suspend User' : 'Activate User'}
      </button>
    </div>
  );
}
