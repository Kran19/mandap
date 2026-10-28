import { Metadata } from 'next';
import { fetchApi } from '@/lib/api/client';
import { VerificationLogsResponse } from '@/types';
import { VerificationLogsClientTable } from './client-table';
import { ShieldCheck } from 'lucide-react';

export const metadata: Metadata = {
  title: 'OTP & Verification Codes Tracker | Admin Panel',
};

export default async function VerificationLogsPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; search?: string; channel?: string; status?: string }>;
}) {
  const params = await searchParams;
  const page = parseInt(params.page || '1', 10);
  const search = params.search || '';
  const channel = params.channel || '';
  const status = params.status || '';

  let response: VerificationLogsResponse | null = null;
  let errorMsg: string | null = null;

  try {
    const query = new URLSearchParams({ page: page.toString(), limit: '20' });
    if (search) query.set('search', search);
    if (channel) query.set('channel', channel);
    if (status) query.set('status', status);

    response = await fetchApi<VerificationLogsResponse>(`/api/v1/admin/verification-logs?${query.toString()}`);
  } catch (error: any) {
    if (error?.status === 403) {
      errorMsg = 'You do not have permission to view verification logs.';
    } else {
      errorMsg = error?.message || 'Failed to load verification logs from API.';
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-bold text-gray-900">OTP & Verification Codes</h1>
            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">
              <ShieldCheck className="w-3.5 h-3.5" />
              DLT & Email Active
            </span>
          </div>
          <p className="text-sm text-gray-500 mt-1">
            Track SMS OTPs sent via DLT Gateway (allsmssolution.in) and Email verification codes used by candidates.
          </p>
        </div>
      </div>

      {errorMsg ? (
        <div className="rounded-xl bg-red-50 border border-red-200 p-4 text-sm text-red-800 flex items-center justify-between">
          <span>{errorMsg}</span>
        </div>
      ) : (
        <VerificationLogsClientTable
          initialData={response}
          search={search}
          selectedChannel={channel}
          selectedStatus={status}
        />
      )}
    </div>
  );
}
