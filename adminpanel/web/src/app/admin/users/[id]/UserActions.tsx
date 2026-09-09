'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { User } from '@/types';
import { updateUserStatus, deleteUser } from './actions';

export default function UserActions({ user }: { user: User }) {
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
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
      if (res?.error) {
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

  const handleDelete = async () => {
    const displayName = [user.firstName, user.lastName].filter(Boolean).join(' ') || user.email || user.id;
    if (!window.confirm(`Are you sure you want to permanently delete user "${displayName}"? This action cannot be undone.`)) {
      return;
    }

    setIsDeleting(true);
    setError(null);
    try {
      const res = await deleteUser(user.id);
      if (res?.error) {
        setError(res.error);
        setIsDeleting(false);
      } else {
        router.push('/admin/users');
      }
    } catch (e: any) {
      setError(e.message || 'An unexpected error occurred.');
      setIsDeleting(false);
    }
  };

  return (
    <div className="flex items-center gap-4">
      {error && <span className="text-sm text-red-600">{error}</span>}
      <button
        type="button"
        onClick={handleToggleStatus}
        disabled={isSubmitting || isDeleting}
        className={`rounded-md px-3 py-2 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 disabled:opacity-50 ${
          isActive 
            ? 'bg-amber-600 hover:bg-amber-500 focus-visible:outline-amber-600' 
            : 'bg-green-600 hover:bg-green-500 focus-visible:outline-green-600'
        }`}
      >
        {isSubmitting ? 'Processing...' : isActive ? 'Suspend User' : 'Activate User'}
      </button>

      <button
        type="button"
        onClick={handleDelete}
        disabled={isSubmitting || isDeleting}
        className="rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600 disabled:opacity-50"
      >
        {isDeleting ? 'Deleting...' : 'Delete User'}
      </button>
    </div>
  );
}

