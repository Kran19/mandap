import { Metadata } from 'next';
import { fetchApi } from '@/lib/api/client';
import { PaginatedResponse, Project } from '@/types';
import { ProjectsClientTable } from './client-table';

export const metadata: Metadata = {
  title: 'Projects | Admin Panel',
};

export default async function ProjectsPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; search?: string }>;
}) {
  const params = await searchParams;
  const page = parseInt(params.page || '1', 10);
  const search = params.search || '';

  let response: PaginatedResponse<Project> | null = null;
  let errorMsg = null;

  try {
    const query = new URLSearchParams({ page: page.toString(), limit: '20' });
    if (search) query.set('search', search);

    response = await fetchApi<PaginatedResponse<Project>>(`/api/v1/admin/projects?${query.toString()}`);
  } catch (error: any) {
    if (error.status === 403) {
      errorMsg = "You do not have permission to view projects.";
    } else {
      errorMsg = error.message || "Failed to load projects.";
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Projects</h1>
      </div>

      {errorMsg ? (
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
      ) : (
        <ProjectsClientTable initialData={response!} search={search} />
      )}
    </div>
  );
}
