import { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { fetchApi } from '@/lib/api/client';
import { AdminRoleModel } from '@/types';
import { ArrowLeft } from 'lucide-react';
import RoleForm from './RoleForm';

export const metadata: Metadata = {
  title: 'Edit Role | Admin Panel',
};

export default async function RoleDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = await params;
  const id = resolvedParams.id;
  
  let role: AdminRoleModel | null = null;
  let allPermissions: any[] = [];
  let errorMsg = null;

  try {
    const [roleRes, permRes] = await Promise.all([
      fetchApi<AdminRoleModel>(`/api/v1/admin/roles/${id}`),
      fetchApi<any[]>('/api/v1/admin/permissions'),
    ]);
    role = roleRes;
    allPermissions = permRes;
  } catch (error: any) {
    if (error.status === 404) {
      notFound();
    } else if (error.status === 403) {
      errorMsg = "You do not have permission to view this role.";
    } else {
      errorMsg = error.message || "Failed to load role.";
    }
  }

  if (errorMsg) {
    return (
      <div className="space-y-6">
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
        <Link href="/admin/roles" className="text-blue-600 hover:underline inline-flex items-center">
          <ArrowLeft className="w-4 h-4 mr-1" /> Back to Roles
        </Link>
      </div>
    );
  }

  if (!role) return null;

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex items-center gap-4">
        <Link href="/admin/roles" className="text-gray-500 hover:text-gray-900">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">Edit Role: {role.name}</h1>
      </div>

      <RoleForm initialData={role} allPermissions={allPermissions} />
    </div>
  );
}
