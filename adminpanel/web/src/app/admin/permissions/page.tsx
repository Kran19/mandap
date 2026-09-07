import { Metadata } from 'next';
import { fetchApi } from '@/lib/api/client';
import { PermissionsClientTable } from './client-table';

export const metadata: Metadata = {
  title: 'Permissions | Admin Panel',
};

export default async function PermissionsPage() {
  let permissions: { action: string }[] = [];
  let errorMsg = null;

  try {
    permissions = await fetchApi<{ action: string }[]>('/api/v1/admin/permissions');
  } catch (error: any) {
    if (error.status === 403) {
      errorMsg = "You do not have permission to view permissions.";
    } else {
      errorMsg = error.message || "Failed to load permissions.";
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">System Permissions</h1>
      </div>

      {errorMsg ? (
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
      ) : (
        <PermissionsClientTable data={permissions} />
      )}
    </div>
  );
}
