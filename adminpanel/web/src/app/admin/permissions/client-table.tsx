'use client';

import { DataTable } from '@/components/tables/DataTable';

export function PermissionsClientTable({ data }: { data: { action: string }[] }) {
  const columns = [
    {
      header: 'Permission Action',
      accessorKey: 'action' as const,
    },
  ];

  return (
    <div className="space-y-4">
      <DataTable
        data={data}
        columns={columns}
        rowKey={(row) => row.action}
        emptyMessage="No permissions found."
      />
    </div>
  );
}
