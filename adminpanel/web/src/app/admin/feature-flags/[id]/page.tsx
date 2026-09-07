import { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { fetchApi } from '@/lib/api/client';
import { FeatureFlag } from '@/types';
import { ArrowLeft } from 'lucide-react';
import FeatureFlagForm from './FeatureFlagForm';

export const metadata: Metadata = {
  title: 'Edit Feature Flag | Admin Panel',
};

export default async function FeatureFlagDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const resolvedParams = await params;
  const id = resolvedParams.id;
  
  let featureFlag: FeatureFlag | null = null;
  let errorMsg = null;

  try {
    featureFlag = await fetchApi<FeatureFlag>(`/api/v1/admin/feature-flags/${id}`);
  } catch (error: any) {
    if (error.status === 404) {
      notFound();
    } else if (error.status === 403) {
      errorMsg = "You do not have permission to view this feature flag.";
    } else {
      errorMsg = error.message || "Failed to load feature flag.";
    }
  }

  if (errorMsg) {
    return (
      <div className="space-y-6">
        <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{errorMsg}</div>
        <Link href="/admin/feature-flags" className="text-blue-600 hover:underline inline-flex items-center">
          <ArrowLeft className="w-4 h-4 mr-1" /> Back to Feature Flags
        </Link>
      </div>
    );
  }

  if (!featureFlag) return null;

  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex items-center gap-4">
        <Link href="/admin/feature-flags" className="text-gray-500 hover:text-gray-900">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">Edit Feature Flag: {featureFlag.key}</h1>
      </div>

      <FeatureFlagForm initialData={featureFlag} />
    </div>
  );
}
