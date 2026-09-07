import React from 'react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Pagination } from '@/types';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface Column<T> {
  header: string;
  accessorKey?: keyof T;
  cell?: (item: T) => React.ReactNode;
}

interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  pagination?: Pagination;
  onPageChange?: (page: number) => void;
  isLoading?: boolean;
  emptyMessage?: string;
  rowKey: (item: T) => string;
}

export function DataTable<T>({
  data,
  columns,
  pagination,
  onPageChange,
  isLoading,
  emptyMessage = 'No results found.',
  rowKey,
}: DataTableProps<T>) {
  return (
    <div className="space-y-4">
      <div className="rounded-md border bg-white shadow-sm overflow-hidden">
        <Table>
          <TableHeader className="bg-gray-50/50">
            <TableRow>
              {columns.map((col, i) => (
                <TableHead key={i} className="font-semibold text-gray-700">
                  {col.header}
                </TableHead>
              ))}
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={columns.length} className="h-24 text-center">
                  Loading...
                </TableCell>
              </TableRow>
            ) : data.length === 0 ? (
              <TableRow>
                <TableCell colSpan={columns.length} className="h-24 text-center text-gray-500">
                  {emptyMessage}
                </TableCell>
              </TableRow>
            ) : (
              data.map((row) => (
                <TableRow key={rowKey(row)}>
                  {columns.map((col, i) => (
                    <TableCell key={i}>
                      {col.cell ? col.cell(row) : col.accessorKey ? String(row[col.accessorKey]) : null}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
      {pagination && (
        <div className="flex items-center justify-between px-2">
          <div className="text-sm text-gray-500">
            Showing <span className="font-medium">{Math.min((pagination.page - 1) * pagination.limit + 1, pagination.total)}</span> to <span className="font-medium">{Math.min(pagination.page * pagination.limit, pagination.total)}</span> of{' '}
            <span className="font-medium">{pagination.total}</span> results
          </div>
          <div className="flex items-center space-x-2">
            <button
              onClick={() => onPageChange?.(pagination.page - 1)}
              disabled={pagination.page <= 1}
              className="inline-flex items-center justify-center rounded-md border border-gray-300 p-1 text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            <span className="text-sm text-gray-600">
              Page {pagination.page} of {Math.max(1, Math.ceil(pagination.total / pagination.limit))}
            </span>
            <button
              onClick={() => onPageChange?.(pagination.page + 1)}
              disabled={pagination.page >= Math.ceil(pagination.total / pagination.limit)}
              className="inline-flex items-center justify-center rounded-md border border-gray-300 p-1 text-sm font-medium hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
