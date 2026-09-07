import { Metadata } from 'next';
import { fetchApi } from '@/lib/api/client';
import { PaginatedResponse, FeatureFlag } from '@/types';
import { FeatureFlagsClientTable } from './client-table';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Feature Flags | Admin Panel',
};

export default async function FeatureFlagsPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; search?: string }>;
}) {
  const params = await searchParams;
  const page = parseInt(params.page || '1', 10);
  const search = params.search || '';

  let response: PaginatedResponse<FeatureFlag> | null = null;
  let errorMsg = null;

  try {
    const query = new URLSearchParams({ page: page.toString(), limit: '20' });
    if (search) query.set('search', search);

    response = await fetchApi<PaginatedResponse<FeatureFlag>>(`/api/v1/admin/feature-flags?${query.toString()}`);
  } catch (error: any) {
    if (error.status === 403) {
      errorMsg = "You do not have permission to view feature flags.";
    } else {
      errorMsg = error.message || "Failed to load feature flags.";
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Feature Flags</h1>
        <Link 
          href="/admin/feature-flags/new"
          className="rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600"
        >
          Create Flag
        </Link>
      </div>

      {errorMsg ? (
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
      ) : (
        <FeatureFlagsClientTable initialData={response!} search={search} />
      )}
    </div>
  );
}
