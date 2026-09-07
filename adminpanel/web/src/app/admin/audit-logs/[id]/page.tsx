import { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { fetchApi } from '@/lib/api/client';
import { AuditLog } from '@/types';
import { ArrowLeft } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Audit Log Details | Admin Panel',
};

export default async function AuditLogDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = await params;
  const id = resolvedParams.id;
  
  let auditLog: AuditLog | null = null;
  let errorMsg = null;

  try {
    auditLog = await fetchApi<AuditLog>(`/api/v1/admin/audit-logs/${id}`);
  } catch (error: any) {
    if (error.status === 404) {
      notFound();
    } else if (error.status === 403) {
      errorMsg = "You do not have permission to view this audit log.";
    } else {
      errorMsg = error.message || "Failed to load audit log.";
    }
  }

  if (errorMsg) {
    return (
      <div className="space-y-6">
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
        <Link href="/admin/audit-logs" className="text-blue-600 hover:underline inline-flex items-center">
          <ArrowLeft className="w-4 h-4 mr-1" /> Back to Audit Logs
        </Link>
      </div>
    );
  }

  if (!auditLog) return null;

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex items-center gap-4">
        <Link href="/admin/audit-logs" className="text-gray-500 hover:text-gray-900">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">Audit Log Details</h1>
      </div>

      <div className="bg-white shadow-sm ring-1 ring-gray-900/5 sm:rounded-xl">
        <div className="px-4 py-6 sm:p-8">
          <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-8">
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">ID</dt>
              <dd className="mt-1 text-sm text-gray-900">{auditLog.id}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Action</dt>
              <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-100 p-1 rounded inline-block">{auditLog.action}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Actor User</dt>
              <dd className="mt-1 text-sm text-gray-900">
                {auditLog.actorUser ? (
                  <Link href={`/admin/users/${auditLog.actorUserId}`} className="text-blue-600 hover:underline">
                    {auditLog.actorUser.firstName} {auditLog.actorUser.lastName} ({auditLog.actorUser.email})
                  </Link>
                ) : (
                  auditLog.actorUserId || 'System'
                )}
              </dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Timestamp</dt>
              <dd className="mt-1 text-sm text-gray-900" suppressHydrationWarning>{new Date(auditLog.createdAt).toLocaleString()}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Target Resource</dt>
              <dd className="mt-1 text-sm text-gray-900">{auditLog.targetResource}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Target Resource ID</dt>
              <dd className="mt-1 text-sm text-gray-900 font-mono text-xs">{auditLog.targetResourceId || '-'}</dd>
            </div>
            <div className="sm:col-span-2">
              <dt className="text-sm font-medium text-gray-500">Previous State</dt>
              <dd className="mt-1 text-sm text-gray-900 bg-gray-50 p-4 rounded-md overflow-x-auto">
                <pre>{auditLog.previousState ? JSON.stringify(auditLog.previousState, null, 2) : 'None'}</pre>
              </dd>
            </div>
            <div className="sm:col-span-2">
              <dt className="text-sm font-medium text-gray-500">New State</dt>
              <dd className="mt-1 text-sm text-gray-900 bg-gray-50 p-4 rounded-md overflow-x-auto">
                <pre>{auditLog.newState ? JSON.stringify(auditLog.newState, null, 2) : 'None'}</pre>
              </dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
  );
}
