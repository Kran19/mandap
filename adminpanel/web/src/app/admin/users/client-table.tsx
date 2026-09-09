'use client';

import { useRouter, usePathname, useSearchParams } from 'next/navigation';
import { useState, useCallback } from 'react';
import { PaginatedResponse, User } from '@/types';
import { DataTable } from '@/components/tables/DataTable';
import { StatusBadge } from '@/components/ui/StatusBadge';
import Link from 'next/link';
import { Search } from 'lucide-react';
import { deleteUser } from './actions';

export function UsersClientTable({ initialData, search }: { initialData: PaginatedResponse<User>, search: string }) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  
  const [searchInput, setSearchInput] = useState(search);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const createQueryString = useCallback(
    (name: string, value: string) => {
      const params = new URLSearchParams(searchParams.toString());
      if (value) {
        params.set(name, value);
      } else {
        params.delete(name);
      }
      return params.toString();
    },
    [searchParams]
  );

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    router.push(pathname + '?' + createQueryString('search', searchInput));
  };

  const handlePageChange = (page: number) => {
    router.push(pathname + '?' + createQueryString('page', page.toString()));
  };

  const handleDeleteUser = async (user: User) => {
    const displayName = [user.firstName, user.lastName].filter(Boolean).join(' ') || user.email || user.id;
    if (!window.confirm(`Are you sure you want to permanently delete user "${displayName}"? This action cannot be undone.`)) {
      return;
    }

    setDeletingId(user.id);
    setActionError(null);
    try {
      const res = await deleteUser(user.id);
      if (res?.error) {
        setActionError(res.error);
      } else {
        router.refresh();
      }
    } catch (err: any) {
      setActionError(err.message || 'Failed to delete user.');
    } finally {
      setDeletingId(null);
    }
  };

  const columns = [
    {
      header: 'Name',
      cell: (user: User) => (
        <div className="font-medium text-gray-900">
          <Link href={`/admin/users/${user.id}`} className="hover:underline text-blue-600">
            {user.firstName} {user.lastName}
          </Link>
        </div>
      ),
    },
    { header: 'Email', accessorKey: 'email' as keyof User },
    {
      header: 'Status',
      cell: (user: User) => <StatusBadge status={user.status} />,
    },
    {
      header: 'Created',
      cell: (user: User) => new Date(user.createdAt).toLocaleDateString('en-GB'),
    },
    {
      header: 'Actions',
      cell: (user: User) => (
        <div className="flex items-center gap-3">
          <Link href={`/admin/users/${user.id}`} className="text-sm text-blue-600 hover:text-blue-900 font-medium">
            View
          </Link>
          <button
            type="button"
            onClick={() => handleDeleteUser(user)}
            disabled={deletingId === user.id}
            className="text-sm text-red-600 hover:text-red-900 font-medium disabled:opacity-50"
          >
            {deletingId === user.id ? 'Deleting...' : 'Delete'}
          </button>
        </div>
      ),
    }
  ];

  return (
    <div className="space-y-4">
      {actionError && (
        <div className="rounded-md bg-red-50 p-3 text-sm text-red-700 flex justify-between items-center">
          <span>{actionError}</span>
          <button
            type="button"
            onClick={() => setActionError(null)}
            className="text-xs font-semibold text-red-800 hover:text-red-950 ml-4 underline"
          >
            Dismiss
          </button>
        </div>
      )}

      <form onSubmit={handleSearch} className="flex gap-2 max-w-sm">
        <div className="relative flex-1">
          <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
            <Search className="h-4 w-4 text-gray-400" />
          </div>
          <input
            type="text"
            className="block w-full rounded-md border border-gray-300 pl-10 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            placeholder="Search users..."
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
          />
        </div>
        <button
          type="submit"
          className="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
        >
          Search
        </button>
      </form>

      <DataTable
        data={initialData?.data || []}
        columns={columns}
        pagination={initialData?.meta}
        onPageChange={handlePageChange}
        rowKey={(row) => row.id}
        emptyMessage={search ? "No users found matching your search." : "No users found."}
      />
    </div>
  );
}
