import { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { fetchApi } from '@/lib/api/client';
import { Plan } from '@/types';
import { ArrowLeft } from 'lucide-react';
import PlanForm from './PlanForm';

export const metadata: Metadata = {
  title: 'Edit Plan | Admin Panel',
};

export default async function PlanDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = await params;
  const id = resolvedParams.id;
  
  let plan: Plan | null = null;
  let errorMsg = null;

  try {
    plan = await fetchApi<Plan>(`/api/v1/admin/plans/${id}`);
  } catch (error: any) {
    if (error.status === 404) {
      notFound();
    } else if (error.status === 403) {
      errorMsg = "You do not have permission to view this plan.";
    } else {
      errorMsg = error.message || "Failed to load plan.";
    }
  }

  if (errorMsg) {
    return (
      <div className="space-y-6">
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
        <Link href="/admin/plans" className="text-blue-600 hover:underline inline-flex items-center">
          <ArrowLeft className="w-4 h-4 mr-1" /> Back to Plans
        </Link>
      </div>
    );
  }

  if (!plan) return null;

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex items-center gap-4">
        <Link href="/admin/plans" className="text-gray-500 hover:text-gray-900">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">Edit Plan: {plan.name}</h1>
      </div>

      <PlanForm initialData={plan} />
    </div>
  );
}
