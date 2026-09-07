import { Metadata } from 'next';
import { fetchApi } from '@/lib/api/client';
import { PaginatedResponse, Organization } from '@/types';
import { redirect } from 'next/navigation';
import { OrganizationsClientTable } from './client-table';

export const metadata: Metadata = {
  title: 'Organizations | Admin Panel',
};

export default async function OrganizationsPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; search?: string }>;
}) {
  const params = await searchParams;
  const page = parseInt(params.page || '1', 10);
  const search = params.search || '';

  let response: PaginatedResponse<Organization> | null = null;
  let errorMsg = null;

  try {
    const query = new URLSearchParams();
    query.set('page', page.toString());
    query.set('limit', '20');
    if (search) query.set('search', search);

    response = await fetchApi<PaginatedResponse<Organization>>(`/api/v1/admin/organizations?${query.toString()}`);
  } catch (error: any) {
    if (error.status === 403) {
      errorMsg = "You do not have permission to view organizations.";
    } else {
      errorMsg = error.message || "Failed to load organizations.";
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Organizations</h1>
      </div>

      {errorMsg ? (
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
      ) : (
        <OrganizationsClientTable initialData={response!} search={search} />
      )}
    </div>
  );
}
