import { Metadata } from 'next';
import { fetchApi } from '@/lib/api/client';
import { PaginatedResponse } from '@/types';
import Link from 'next/link';
import { Users, Building2, Briefcase } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Dashboard | Admin Panel',
};

export default async function DashboardPage() {
  let usersTotal = 0;
  let orgsTotal = 0;
  let projectsTotal = 0;
  let errorMsg = null;

  try {
    const [usersRes, orgsRes, projectsRes] = await Promise.allSettled([
      fetchApi<PaginatedResponse<any>>('/api/v1/admin/users?limit=1'),
      fetchApi<PaginatedResponse<any>>('/api/v1/admin/organizations?limit=1'),
      fetchApi<PaginatedResponse<any>>('/api/v1/admin/projects?limit=1'),
    ]);

    if (usersRes.status === 'fulfilled') usersTotal = usersRes.value.meta.total;
    if (orgsRes.status === 'fulfilled') orgsTotal = orgsRes.value.meta.total;
    if (projectsRes.status === 'fulfilled') projectsTotal = projectsRes.value.meta.total;

  } catch (error: any) {
    errorMsg = "Failed to load dashboard metrics.";
  }

  const stats = [
    { name: 'Total Users', stat: usersTotal, icon: Users, href: '/admin/users', color: 'bg-blue-500' },
    { name: 'Organizations', stat: orgsTotal, icon: Building2, href: '/admin/organizations', color: 'bg-indigo-500' },
    { name: 'Projects', stat: projectsTotal, icon: Briefcase, href: '/admin/projects', color: 'bg-purple-500' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
      </div>

      {errorMsg && (
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
      )}

      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {stats.map((item) => (
          <div key={item.name} className="relative overflow-hidden rounded-lg bg-white px-4 pt-5 pb-12 shadow sm:px-6 sm:pt-6">
            <dt>
              <div className={`absolute rounded-md ${item.color} p-3`}>
                <item.icon className="h-6 w-6 text-white" aria-hidden="true" />
              </div>
              <p className="ml-16 truncate text-sm font-medium text-gray-500">{item.name}</p>
            </dt>
            <dd className="ml-16 flex items-baseline pb-6 sm:pb-7">
              <p className="text-2xl font-semibold text-gray-900">{item.stat}</p>
              <div className="absolute inset-x-0 bottom-0 bg-gray-50 px-4 py-4 sm:px-6">
                <div className="text-sm">
                  <Link href={item.href} className="font-medium text-blue-600 hover:text-blue-500">
                    View all<span className="sr-only"> {item.name}</span>
                  </Link>
                </div>
              </div>
            </dd>
          </div>
        ))}
      </div>
    </div>
  );
}
