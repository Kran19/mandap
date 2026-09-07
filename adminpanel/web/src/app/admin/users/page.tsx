import { Metadata } from 'next';
import Link from 'next/link';
import { fetchApi } from '@/lib/api/client';
import { PaginatedResponse, User } from '@/types';
import { DataTable } from '@/components/tables/DataTable';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { redirect } from 'next/navigation';

export const metadata: Metadata = {
  title: 'Users | Admin Panel',
};

export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; search?: string }>;
}) {
  const params = await searchParams;
  const page = parseInt(params.page || '1', 10);
  const search = params.search || '';

  let response: PaginatedResponse<User> | null = null;
  let errorMsg = null;

  try {
    const query = new URLSearchParams();
    query.set('page', page.toString());
    query.set('limit', '20');
    if (search) query.set('search', search);

    response = await fetchApi<PaginatedResponse<User>>(`/api/v1/admin/users?${query.toString()}`);
  } catch (error: any) {
    if (error.status === 403) {
      errorMsg = "You do not have permission to view users.";
    } else {
      errorMsg = error.message || "Failed to load users.";
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Users</h1>
      </div>

      {errorMsg ? (
        <div className="rounded-md bg-red-50 p-4">
          <p className="text-sm text-red-800">{errorMsg}</p>
        </div>
      ) : (
        <UsersClientTable initialData={response!} search={search} />
      )}
    </div>
  );
}

// Extract the client interactive part
import { UsersClientTable } from './client-table';
