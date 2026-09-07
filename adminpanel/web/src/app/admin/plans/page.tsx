import { Metadata } from 'next';
import { fetchApi } from '@/lib/api/client';
import { PaginatedResponse, Plan } from '@/types';
import { PlansClientTable } from './client-table';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Plans | Admin Panel',
};

export default async function PlansPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; search?: string }>;
}) {
  const params = await searchParams;
  const page = parseInt(params.page || '1', 10);
  const search = params.search || '';

  let response: PaginatedResponse<Plan> | null = null;
  let errorMsg = null;

  try {
    const query = new URLSearchParams({ page: page.toString(), limit: '20' });
    if (search) query.set('search', search);

    response = await fetchApi<PaginatedResponse<Plan>>(`/api/v1/admin/plans?${query.toString()}`);
  } catch (error: any) {
    if (error.status === 403) {
      errorMsg = "You do not have permission to view plans.";
    } else {
      errorMsg = error.message || "Failed to load plans.";
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Plans</h1>
        <Link 
          href="/admin/plans/new"
          className="rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"
        >
          Create Plan
        </Link>
      </div>

      {errorMsg ? (
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
      ) : (
        <PlansClientTable initialData={response!} search={search} />
      )}
    </div>
  );
}
