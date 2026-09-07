import { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import FeatureFlagForm from '../[id]/FeatureFlagForm';

export const metadata: Metadata = {
  title: 'Create Feature Flag | Admin Panel',
};

export default function NewFeatureFlagPage() {
  return (
    <div className="space-y-6 max-w-4xl">
      <div className="flex items-center gap-4">
        <Link href="/admin/feature-flags" className="text-gray-500 hover:text-gray-900">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">Create New Feature Flag</h1>
      </div>

      <FeatureFlagForm />
    </div>
  );
}
