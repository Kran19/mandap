import { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { fetchApi } from '@/lib/api/client';
import { Organization, OrganizationMember, PaginatedResponse } from '@/types';
import { StatusBadge } from '@/components/ui/StatusBadge';
import { ArrowLeft } from 'lucide-react';
import MembershipsTable from './MembershipsTable';

export const metadata: Metadata = {
  title: 'Organization Details | Admin Panel',
};

export default async function OrganizationDetailPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ page?: string }>;
}) {
  const resolvedParams = await params;
  const id = resolvedParams.id;
  const resolvedSearchParams = await searchParams;
  const page = parseInt(resolvedSearchParams.page || '1', 10);
  
  let organization: Organization | null = null;
  let membershipsResponse: PaginatedResponse<OrganizationMember> | null = null;
  let errorMsg = null;

  try {
    organization = await fetchApi<Organization>(`/api/v1/admin/organizations/${id}`);
    
    // Fetch memberships for this org
    const mQuery = new URLSearchParams({ page: page.toString(), limit: '10' });
    membershipsResponse = await fetchApi<PaginatedResponse<OrganizationMember>>(`/api/v1/admin/organizations/${id}/members?${mQuery.toString()}`);
  } catch (error: any) {
    if (error.status === 404) {
      notFound();
    } else if (error.status === 403) {
      errorMsg = "You do not have permission to view this organization.";
    } else {
      errorMsg = error.message || "Failed to load organization.";
    }
  }

  if (errorMsg) {
    return (
      <div className="space-y-6">
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
        <Link href="/admin/organizations" className="text-blue-600 hover:underline inline-flex items-center">
          <ArrowLeft className="w-4 h-4 mr-1" /> Back to Organizations
        </Link>
      </div>
    );
  }

  if (!organization) return null;

  return (
    <div className="space-y-8 max-w-6xl">
      <div className="flex items-center gap-4">
        <Link href="/admin/organizations" className="text-gray-500 hover:text-gray-900">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">Organization: {organization.name}</h1>
        <StatusBadge status={organization.status} />
      </div>

      <div className="bg-white shadow-sm ring-1 ring-gray-900/5 sm:rounded-xl">
        <div className="px-4 py-6 sm:p-8">
          <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-8">
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">ID</dt>
              <dd className="mt-1 text-sm text-gray-900">{organization.id}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Slug</dt>
              <dd className="mt-1 text-sm text-gray-900">{organization.slug}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Status</dt>
              <dd className="mt-1 text-sm text-gray-900">{organization.status}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Created At</dt>
              <dd className="mt-1 text-sm text-gray-900" suppressHydrationWarning>{new Date(organization.createdAt).toLocaleString()}</dd>
            </div>
          </dl>
        </div>
      </div>

      <div>
        <h2 className="text-xl font-bold text-gray-900 mb-4">Memberships</h2>
        {membershipsResponse ? (
          <MembershipsTable 
            organizationId={organization.id} 
            initialData={membershipsResponse} 
          />
        ) : (
          <p className="text-sm text-gray-500">Memberships could not be loaded.</p>
        )}
      </div>
    </div>
  );
}
