'use client';

import { useRouter, usePathname, useSearchParams } from 'next/navigation';
import { useState, useCallback } from 'react';
import { VerificationLogsResponse, VerificationLog, VerificationChannel, VerificationStatus } from '@/types';
import { DataTable } from '@/components/tables/DataTable';
import { 
  Search, 
  MessageSquare, 
  Mail, 
  CheckCircle2, 
  Clock, 
  AlertCircle, 
  Smartphone, 
  ShieldCheck,
  TrendingUp,
  Filter
} from 'lucide-react';

interface Props {
  initialData: VerificationLogsResponse | null;
  search: string;
  selectedChannel?: string;
  selectedStatus?: string;
}

export function VerificationLogsClientTable({
  initialData,
  search,
  selectedChannel = '',
  selectedStatus = '',
}: Props) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const [searchInput, setSearchInput] = useState(search);
  const stats = initialData?.stats;

  const createQueryString = useCallback(
    (updates: Record<string, string | null>) => {
      const params = new URLSearchParams(searchParams.toString());
      Object.entries(updates).forEach(([key, val]) => {
        if (val && val.length > 0) {
          params.set(key, val);
        } else {
          params.delete(key);
        }
      });
      return params.toString();
    },
    [searchParams]
  );

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    router.push(pathname + '?' + createQueryString({ search: searchInput, page: '1' }));
  };

  const handleChannelFilter = (channel: string) => {
    router.push(pathname + '?' + createQueryString({ channel: channel || null, page: '1' }));
  };

  const handleStatusFilter = (status: string) => {
    router.push(pathname + '?' + createQueryString({ status: status || null, page: '1' }));
  };

  const handlePageChange = (page: number) => {
    router.push(pathname + '?' + createQueryString({ page: page.toString() }));
  };

  const columns = [
    {
      header: 'Recipient & Candidate',
      cell: (log: VerificationLog) => {
        const candidateName = log.user 
          ? `${log.user.firstName || ''} ${log.user.lastName || ''}`.trim() || 'Candidate'
          : (log.metadata?.candidateName || 'Candidate');

        return (
          <div>
            <div className="font-semibold text-gray-900">{log.identifier}</div>
            <div className="text-xs text-gray-500 font-medium">{candidateName}</div>
          </div>
        );
      },
    },
    {
      header: 'Channel',
      cell: (log: VerificationLog) => {
        if (log.channel === 'SMS') {
          return (
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
              <Smartphone className="w-3.5 h-3.5 text-emerald-600" />
              DLT SMS
            </span>
          );
        }
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-200">
            <Mail className="w-3.5 h-3.5 text-blue-600" />
            Email Code
          </span>
        );
      },
    },
    {
      header: 'Purpose',
      cell: (log: VerificationLog) => (
        <span className="text-xs font-semibold tracking-wide uppercase px-2 py-0.5 rounded bg-gray-100 text-gray-700">
          {log.purpose}
        </span>
      ),
    },
    {
      header: 'Status',
      cell: (log: VerificationLog) => {
        if (log.status === 'VERIFIED') {
          return (
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
              <CheckCircle2 className="w-3.5 h-3.5 text-green-600" />
              Verified
            </span>
          );
        }
        if (log.status === 'FAILED') {
          return (
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
              <AlertCircle className="w-3.5 h-3.5 text-red-600" />
              Failed
            </span>
          );
        }
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-800">
            <Clock className="w-3.5 h-3.5 text-amber-600" />
            Pending
          </span>
        );
      },
    },
    {
      header: 'Attempts',
      cell: (log: VerificationLog) => (
        <span className="text-sm font-medium text-gray-700">{log.attempts}</span>
      ),
    },
    {
      header: 'Gateway Delivery',
      cell: (log: VerificationLog) => (
        <div className="max-w-[200px] text-xs">
          <div className="font-mono text-gray-800 truncate" title={log.gatewayMsgId || 'None'}>
            ID: {log.gatewayMsgId || 'N/A'}
          </div>
          <div className="text-gray-500 truncate" title={log.gatewayStatus || ''}>
            {log.gatewayStatus || 'Dispatched'}
          </div>
        </div>
      ),
    },
    {
      header: 'Sent / Verified At',
      cell: (log: VerificationLog) => (
        <div className="text-xs text-gray-600">
          <div>Sent: {new Date(log.createdAt).toLocaleDateString()} {new Date(log.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</div>
          {log.verifiedAt && (
            <div className="text-green-700 font-medium">
              Done: {new Date(log.verifiedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
            </div>
          )}
        </div>
      ),
    },
  ];

  return (
    <div className="space-y-6">
      {/* 4 Metric Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Codes */}
        <div className="bg-white rounded-xl p-5 border border-gray-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-500">Total Codes Dispatched</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{stats?.totalAll ?? 0}</p>
            <p className="text-xs text-gray-500 mt-1">SMS & Email verifications</p>
          </div>
          <div className="w-12 h-12 rounded-lg bg-indigo-50 flex items-center justify-center text-indigo-600">
            <MessageSquare className="w-6 h-6" />
          </div>
        </div>

        {/* DLT SMS Messages */}
        <div className="bg-white rounded-xl p-5 border border-gray-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-500">DLT SMS OTPs</p>
            <p className="text-2xl font-bold text-emerald-600 mt-1">{stats?.totalSms ?? 0}</p>
            <p className="text-xs text-gray-500 mt-1">Via allsmssolution.in</p>
          </div>
          <div className="w-12 h-12 rounded-lg bg-emerald-50 flex items-center justify-center text-emerald-600">
            <Smartphone className="w-6 h-6" />
          </div>
        </div>

        {/* Email Codes */}
        <div className="bg-white rounded-xl p-5 border border-gray-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-500">Email Verification Codes</p>
            <p className="text-2xl font-bold text-blue-600 mt-1">{stats?.totalEmail ?? 0}</p>
            <p className="text-xs text-gray-500 mt-1">Inbox verification tokens</p>
          </div>
          <div className="w-12 h-12 rounded-lg bg-blue-50 flex items-center justify-center text-blue-600">
            <Mail className="w-6 h-6" />
          </div>
        </div>

        {/* Verification Success Rate */}
        <div className="bg-white rounded-xl p-5 border border-gray-200 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-500">Success Rate</p>
            <p className="text-2xl font-bold text-gray-900 mt-1">{stats?.verificationRate ?? 0}%</p>
            <p className="text-xs text-emerald-600 font-medium mt-1">{stats?.totalVerified ?? 0} verified codes</p>
          </div>
          <div className="w-12 h-12 rounded-lg bg-green-50 flex items-center justify-center text-green-600">
            <TrendingUp className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        {/* Channel Filter Pills */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => handleChannelFilter('')}
            className={`px-3.5 py-1.5 text-xs font-semibold rounded-lg transition-colors ${
              selectedChannel === ''
                ? 'bg-gray-900 text-white shadow-sm'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            All Channels
          </button>
          <button
            onClick={() => handleChannelFilter('SMS')}
            className={`px-3.5 py-1.5 text-xs font-semibold rounded-lg transition-colors flex items-center gap-1.5 ${
              selectedChannel === 'SMS'
                ? 'bg-emerald-600 text-white shadow-sm'
                : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100'
            }`}
          >
            <Smartphone className="w-3.5 h-3.5" />
            DLT SMS ({stats?.totalSms ?? 0})
          </button>
          <button
            onClick={() => handleChannelFilter('EMAIL')}
            className={`px-3.5 py-1.5 text-xs font-semibold rounded-lg transition-colors flex items-center gap-1.5 ${
              selectedChannel === 'EMAIL'
                ? 'bg-blue-600 text-white shadow-sm'
                : 'bg-blue-50 text-blue-700 hover:bg-blue-100'
            }`}
          >
            <Mail className="w-3.5 h-3.5" />
            Email Codes ({stats?.totalEmail ?? 0})
          </button>
        </div>

        {/* Status Dropdown & Search Form */}
        <div className="flex items-center gap-3">
          <div className="relative">
            <select
              value={selectedStatus}
              onChange={(e) => handleStatusFilter(e.target.value)}
              aria-label="Filter verification logs by status"
              className="text-xs bg-gray-50 border border-gray-300 rounded-lg px-3 py-2 pr-8 font-medium text-gray-700 focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <option value="">All Statuses</option>
              <option value="VERIFIED">Verified</option>
              <option value="PENDING">Pending</option>
              <option value="FAILED">Failed</option>
            </select>
          </div>

          <form onSubmit={handleSearch} className="flex gap-2 w-full md:w-64">
            <div className="relative flex-1">
              <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                <Search className="h-4 w-4 text-gray-400" />
              </div>
              <input
                type="text"
                className="block w-full rounded-lg border border-gray-300 pl-9 px-3 py-2 text-xs focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                placeholder="Search phone or email..."
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
              />
            </div>
            <button
              type="submit"
              className="rounded-lg bg-gray-900 px-3 py-2 text-xs font-semibold text-white shadow-sm hover:bg-gray-800 transition"
            >
              Search
            </button>
          </form>
        </div>
      </div>

      {/* Main Data Table */}
      <DataTable
        data={initialData?.data || []}
        columns={columns}
        pagination={initialData?.meta}
        onPageChange={handlePageChange}
        rowKey={(row) => row.id}
        emptyMessage={search ? "No verification logs found matching your query." : "No verification logs recorded yet."}
      />
    </div>
  );
}
