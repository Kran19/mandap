import { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { fetchApi } from '@/lib/api/client';
import { Project } from '@/types';
import { ArrowLeft } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Project Details | Admin Panel',
};

export default async function ProjectDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = await params;
  const id = resolvedParams.id;
  
  let project: Project | null = null;
  let errorMsg = null;

  try {
    project = await fetchApi<Project>(`/api/v1/admin/projects/${id}`);
  } catch (error: any) {
    if (error.status === 404) {
      notFound();
    } else if (error.status === 403) {
      errorMsg = "You do not have permission to view this project.";
    } else {
      errorMsg = error.message || "Failed to load project.";
    }
  }

  if (errorMsg) {
    return (
      <div className="space-y-6">
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
        <Link href="/admin/projects" className="text-blue-600 hover:underline inline-flex items-center">
          <ArrowLeft className="w-4 h-4 mr-1" /> Back to Projects
        </Link>
      </div>
    );
  }

  if (!project) return null;

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex items-center gap-4">
        <Link href="/admin/projects" className="text-gray-500 hover:text-gray-900">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">Project: {project.name}</h1>
      </div>

      <div className="bg-white shadow-sm ring-1 ring-gray-900/5 sm:rounded-xl">
        <div className="px-4 py-6 sm:p-8">
          <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-8">
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">ID</dt>
              <dd className="mt-1 text-sm text-gray-900">{project.id}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Organization</dt>
              <dd className="mt-1 text-sm text-gray-900">
                {project.organization ? (
                  <Link href={`/admin/organizations/${project.organizationId}`} className="text-blue-600 hover:underline">
                    {project.organization.name}
                  </Link>
                ) : (
                  '-'
                )}
              </dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">State Data Size</dt>
              <dd className="mt-1 text-sm text-gray-900">
                {project.stateData ? JSON.stringify(project.stateData).length : 0} bytes
              </dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Created At</dt>
              <dd className="mt-1 text-sm text-gray-900" suppressHydrationWarning>{new Date(project.createdAt).toLocaleString()}</dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
  );
}
