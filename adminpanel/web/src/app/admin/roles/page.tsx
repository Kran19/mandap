import { Metadata } from 'next';
import { fetchApi } from '@/lib/api/client';
import { PaginatedResponse, AdminRoleModel } from '@/types';
import { RolesClientTable } from './client-table';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Roles | Admin Panel',
};

export default async function RolesPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; search?: string }>;
}) {
  const params = await searchParams;
  const page = parseInt(params.page || '1', 10);
  const search = params.search || '';

  let response: PaginatedResponse<AdminRoleModel> | null = null;
  let errorMsg = null;

  try {
    const query = new URLSearchParams({ page: page.toString(), limit: '20' });
    if (search) query.set('search', search);

    response = await fetchApi<PaginatedResponse<AdminRoleModel>>(`/api/v1/admin/roles?${query.toString()}`);
  } catch (error: any) {
    if (error.status === 403) {
      errorMsg = "You do not have permission to view roles.";
    } else {
      errorMsg = error.message || "Failed to load roles.";
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Admin Roles</h1>
        <Link 
          href="/admin/roles/new"
          className="rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"
        >
          Create Role
        </Link>
      </div>

      {errorMsg ? (
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
      ) : (
        <RolesClientTable initialData={response!} search={search} />
      )}
    </div>
  );
}
