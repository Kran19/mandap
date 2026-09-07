import { Metadata } from 'next';
import { fetchApi } from '@/lib/api/client';
import { PaginatedResponse, AuditLog } from '@/types';
import { AuditLogsClientTable } from './client-table';

export const metadata: Metadata = {
  title: 'Audit Logs | Admin Panel',
};

export default async function AuditLogsPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; search?: string }>;
}) {
  const params = await searchParams;
  const page = parseInt(params.page || '1', 10);
  const search = params.search || '';

  let response: PaginatedResponse<AuditLog> | null = null;
  let errorMsg = null;

  try {
    const query = new URLSearchParams({ page: page.toString(), limit: '20' });
    if (search) query.set('search', search);

    response = await fetchApi<PaginatedResponse<AuditLog>>(`/api/v1/admin/audit-logs?${query.toString()}`);
  } catch (error: any) {
    if (error.status === 403) {
      errorMsg = "You do not have permission to view audit logs.";
    } else {
      errorMsg = error.message || "Failed to load audit logs.";
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Audit Logs</h1>
      </div>

      {errorMsg ? (
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
      ) : (
        <AuditLogsClientTable initialData={response!} search={search} />
      )}
    </div>
  );
}
