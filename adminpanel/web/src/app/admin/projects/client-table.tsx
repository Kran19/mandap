'use client';

import { useRouter, usePathname, useSearchParams } from 'next/navigation';
import { useState, useCallback } from 'react';
import { PaginatedResponse, Project } from '@/types';
import { DataTable } from '@/components/tables/DataTable';
import Link from 'next/link';
import { Search } from 'lucide-react';

export function ProjectsClientTable({ initialData, search }: { initialData: PaginatedResponse<Project>, search: string }) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  
  const [searchInput, setSearchInput] = useState(search);

  const createQueryString = useCallback(
    (name: string, value: string) => {
      const params = new URLSearchParams(searchParams.toString());
      if (value) params.set(name, value);
      else params.delete(name);
      return params.toString();
    },
    [searchParams]
  );

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    router.push(pathname + '?' + createQueryString('search', searchInput));
  };

  const handlePageChange = (page: number) => {
    router.push(pathname + '?' + createQueryString('page', page.toString()));
  };

  const columns = [
    {
      header: 'Name',
      cell: (project: Project) => (
        <div className="font-medium text-gray-900">
          <Link href={`/admin/projects/${project.id}`} className="hover:underline text-blue-600">
            {project.name}
          </Link>
        </div>
      ),
    },
    { 
      header: 'Organization', 
      cell: (project: Project) => project.organization?.name || '-'
    },
    {
      header: 'Created',
      cell: (project: Project) => new Date(project.createdAt).toLocaleDateString('en-GB'),
    },
    {
      header: 'Actions',
      cell: (project: Project) => (
        <Link href={`/admin/projects/${project.id}`} className="text-sm text-blue-600 hover:text-blue-900">
          View
        </Link>
      ),
    }
  ];

  return (
    <div className="space-y-4">
      <form onSubmit={handleSearch} className="flex gap-2 max-w-sm">
        <div className="relative flex-1">
          <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
            <Search className="h-4 w-4 text-gray-400" />
          </div>
          <input
            type="text"
            className="block w-full rounded-md border border-gray-300 pl-10 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            placeholder="Search projects..."
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
          />
        </div>
        <button
          type="submit"
          className="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
        >
          Search
        </button>
      </form>

      <DataTable
        data={initialData?.data || []}
        columns={columns}
        pagination={initialData?.meta}
        onPageChange={handlePageChange}
        rowKey={(row) => row.id}
        emptyMessage={search ? "No projects found matching your search." : "No projects found."}
      />
    </div>
  );
}
