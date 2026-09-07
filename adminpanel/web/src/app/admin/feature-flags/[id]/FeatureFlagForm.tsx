'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { FeatureFlag } from '@/types';
import { saveFeatureFlag } from './actions';

const featureFlagSchema = z.object({
  key: z.string().min(1, 'Key is required'),
  description: z.string().optional(),
  type: z.enum(['BOOLEAN', 'STRING', 'NUMBER', 'JSON']),
  value: z.string().optional(),
  isEnabled: z.boolean().default(true),
});

type FeatureFlagFormValues = z.infer<typeof featureFlagSchema>;

interface FeatureFlagFormProps {
  initialData?: FeatureFlag;
}

export default function FeatureFlagForm({ initialData }: FeatureFlagFormProps) {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  const form = useForm<FeatureFlagFormValues>({
    resolver: zodResolver(featureFlagSchema) as any,
    defaultValues: initialData ? {
      key: initialData.key,
      description: initialData.description || '',
      type: initialData.type as any,
      value: initialData.value || '',
      isEnabled: initialData.isEnabled,
    } : {
      key: '', type: 'BOOLEAN', value: '', isEnabled: false
    }
  });

  const onSubmit = async (values: FeatureFlagFormValues) => {
    setError(null);
    try {
      const isEditing = !!initialData;
      const res = await saveFeatureFlag(isEditing ? initialData.id : null, values);
      if (res.error) {
        setError(res.error);
        return;
      }
      
      router.push('/admin/feature-flags');
      router.refresh();
    } catch (err: any) {
      setError(err.message || 'An unexpected error occurred.');
    }
  };

  return (
    <form onSubmit={form.handleSubmit(onSubmit as any)} className="space-y-6 bg-white p-6 shadow-sm ring-1 ring-gray-900/5 sm:rounded-xl">
      {error && <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{error}</div>}
      
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
        <div className="sm:col-span-2">
          <label className="block text-sm font-medium text-gray-700">Key</label>
          <input {...form.register('key')} className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" disabled={!!initialData} />
          {form.formState.errors.key && <p className="mt-1 text-sm text-red-600">{form.formState.errors.key.message}</p>}
        </div>

        <div className="sm:col-span-2">
          <label className="block text-sm font-medium text-gray-700">Description</label>
          <input {...form.register('description')} className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Type</label>
          <select {...form.register('type')} className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500">
            <option value="BOOLEAN">Boolean</option>
            <option value="STRING">String</option>
            <option value="NUMBER">Number</option>
            <option value="JSON">JSON</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Value (if not boolean)</label>
          <input {...form.register('value')} className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" />
        </div>

        <div className="sm:col-span-2 flex items-center gap-2">
          <input type="checkbox" {...form.register('isEnabled')} className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500" />
          <label className="text-sm font-medium text-gray-700">Is Enabled globally</label>
        </div>
      </div>

      <div className="border-t pt-6 flex justify-end">
        <button
          type="submit"
          disabled={form.formState.isSubmitting}
          className="rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 disabled:opacity-50"
        >
          {form.formState.isSubmitting ? 'Saving...' : 'Save Feature Flag'}
        </button>
      </div>
    </form>
  );
}
