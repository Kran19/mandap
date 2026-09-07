import { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import RoleForm from '../[id]/RoleForm';
import { fetchApi } from '@/lib/api/client';

export const metadata: Metadata = {
  title: 'Create Role | Admin Panel',
};

export default async function NewRolePage() {
  let allPermissions: any[] = [];
  try {
    allPermissions = await fetchApi<any[]>('/api/v1/admin/permissions');
  } catch (e) {
    //
  }

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex items-center gap-4">
        <Link href="/admin/roles" className="text-gray-500 hover:text-gray-900">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">Create New Role</h1>
      </div>

      <RoleForm allPermissions={allPermissions} />
    </div>
  );
}
