import { Metadata } from 'next';
import Link from 'next/link';
import { notFound, redirect } from 'next/navigation';
import { fetchApi } from '@/lib/api/client';
import { User } from '@/types';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { ArrowLeft } from 'lucide-react';
import UserActions from './UserActions';

export const metadata: Metadata = {
  title: 'User Details | Admin Panel',
};

export default async function UserDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = await params;
  const id = resolvedParams.id;
  
  let user: User | null = null;
  let errorMsg = null;

  try {
    user = await fetchApi<User>(`/api/v1/admin/users/${id}`);
  } catch (error: any) {
    if (error.status === 404) {
      notFound();
    } else if (error.status === 403) {
      errorMsg = "You do not have permission to view this user.";
    } else {
      errorMsg = error.message || "Failed to load user.";
    }
  }

  if (errorMsg) {
    return (
      <div className="space-y-6">
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
        <Link href="/admin/users" className="text-blue-600 hover:underline inline-flex items-center">
          <ArrowLeft className="w-4 h-4 mr-1" /> Back to Users
        </Link>
      </div>
    );
  }

  if (!user) return null;

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex items-center gap-4">
        <Link href="/admin/users" className="text-gray-500 hover:text-gray-900">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">User Details</h1>
        <StatusBadge status={user.status} />
      </div>

      <div className="bg-white shadow-sm ring-1 ring-gray-900/5 sm:rounded-xl md:col-span-2">
        <div className="px-4 py-6 sm:p-8">
          <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-8">
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">ID</dt>
              <dd className="mt-1 text-sm text-gray-900">{user.id}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Email</dt>
              <dd className="mt-1 text-sm text-gray-900">{user.email}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">First Name</dt>
              <dd className="mt-1 text-sm text-gray-900">{user.firstName || '-'}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Last Name</dt>
              <dd className="mt-1 text-sm text-gray-900">{user.lastName || '-'}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Created At</dt>
              <dd className="mt-1 text-sm text-gray-900" suppressHydrationWarning>{new Date(user.createdAt).toLocaleString()}</dd>
            </div>
          </dl>
        </div>
        <div className="flex items-center justify-end gap-x-6 border-t border-gray-900/10 px-4 py-4 sm:px-8 bg-gray-50 rounded-b-xl">
          <UserActions user={user} />
        </div>
      </div>
    </div>
  );
}
