'use client';

import { useRouter, usePathname, useSearchParams } from 'next/navigation';
import { useCallback, useState } from 'react';
import { OrganizationMember, PaginatedResponse } from '@/types';
import { DataTable } from '@/components/tables/DataTable';
import { removeMember, updateMemberRole } from './actions';
import Link from 'next/link';

export default function MembershipsTable({ 
  organizationId, 
  initialData 
}: { 
  organizationId: string;
  initialData: PaginatedResponse<OrganizationMember> 
}) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [error, setError] = useState<string | null>(null);
  
  const createQueryString = useCallback(
    (name: string, value: string) => {
      const params = new URLSearchParams(searchParams.toString());
      params.set(name, value);
      return params.toString();
    },
    [searchParams]
  );

  const handlePageChange = (page: number) => {
    router.push(pathname + '?' + createQueryString('page', page.toString()));
  };

  const handleRemove = async (userId: string) => {
    if (!window.confirm("Are you sure you want to remove this member from the organization?")) return;
    setError(null);
    try {
      const res = await removeMember(organizationId, userId);
      if (res.error) setError(res.error);
    } catch (e: any) {
      setError(e.message || "Removal failed");
    }
  };

  const handleChangeRole = async (userId: string, currentRole: string) => {
    // Only EDITOR/VIEWER changes are supported through generic endpoints
    if (currentRole === 'OWNER') {
      alert('OWNER role cannot be modified through this interface.');
      return;
    }
    
    const newRole = currentRole === 'EDITOR' ? 'VIEWER' : 'EDITOR';
    if (!window.confirm(`Are you sure you want to change this member to ${newRole}?`)) return;

    setError(null);
    try {
      const res = await updateMemberRole(organizationId, userId, newRole);
      if (res.error) setError(res.error);
    } catch (e: any) {
      setError(e.message || "Update failed");
    }
  };

  const columns = [
    {
      header: 'User',
      cell: (member: OrganizationMember) => (
        <div>
          <div className="font-medium text-gray-900">
            <Link href={`/admin/users/${member.userId}`} className="hover:underline text-blue-600">
              {member.user?.firstName} {member.user?.lastName}
            </Link>
          </div>
          <div className="text-xs text-gray-500">{member.user?.email}</div>
        </div>
      ),
    },
    {
      header: 'Role',
      cell: (member: OrganizationMember) => (
        <span className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ${
          member.role === 'OWNER' ? 'bg-purple-50 text-purple-700 ring-1 ring-inset ring-purple-700/10' :
          member.role === 'EDITOR' ? 'bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-700/10' :
          'bg-gray-50 text-gray-600 ring-1 ring-inset ring-gray-500/10'
        }`}>
          {member.role}
        </span>
      ),
    },
    {
      header: 'Joined At',
      cell: (member: OrganizationMember) => new Date(member.createdAt).toLocaleDateString(),
    },
    {
      header: 'Actions',
      cell: (member: OrganizationMember) => (
        <div className="flex gap-2">
          {member.role !== 'OWNER' && (
            <>
              <button 
                onClick={() => handleChangeRole(member.userId, member.role)}
                className="text-xs font-medium text-blue-600 hover:text-blue-900 bg-blue-50 px-2 py-1 rounded"
              >
                Make {member.role === 'EDITOR' ? 'VIEWER' : 'EDITOR'}
              </button>
              <button 
                onClick={() => handleRemove(member.userId)}
                className="text-xs font-medium text-red-600 hover:text-red-900 bg-red-50 px-2 py-1 rounded"
              >
                Remove
              </button>
            </>
          )}
        </div>
      ),
    }
  ];

  return (
    <div className="space-y-4">
      {error && <div className="p-3 bg-red-50 text-red-800 text-sm rounded-md">{error}</div>}
      
      <DataTable
        data={initialData.data}
        columns={columns}
        pagination={initialData.meta}
        onPageChange={handlePageChange}
        rowKey={(row) => row.id}
        emptyMessage="No members found in this organization."
      />
    </div>
  );
}
