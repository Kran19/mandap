'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Plan } from '@/types';
import { Plus, Trash2 } from 'lucide-react';

const planSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  slug: z.string().min(1, 'Slug is required'),
  description: z.string().optional(),
  monthlyPrice: z.coerce.number().optional(),
  yearlyPrice: z.coerce.number().optional(),
  currency: z.string().default('USD'),
  status: z.string().default('ACTIVE'),
  features: z.array(z.object({
    featureKey: z.string().min(1, 'Feature key is required'),
    enabled: z.boolean().default(true),
  })).optional(),
  limits: z.array(z.object({
    key: z.string().min(1, 'Limit key is required'),
    value: z.coerce.number().min(0, 'Limit must be positive'),
  })).optional(),
});

type PlanFormValues = z.infer<typeof planSchema>;

interface PlanFormProps {
  initialData?: Plan;
}

export default function PlanForm({ initialData }: PlanFormProps) {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  const form = useForm<PlanFormValues>({
    resolver: zodResolver(planSchema) as any,
    defaultValues: initialData ? {
      name: initialData.name,
      slug: initialData.slug,
      description: initialData.description || '',
      monthlyPrice: initialData.monthlyPrice ? parseFloat(initialData.monthlyPrice) : undefined,
      yearlyPrice: initialData.yearlyPrice ? parseFloat(initialData.yearlyPrice) : undefined,
      currency: initialData.currency,
      status: initialData.status,
      features: initialData.features?.map(f => ({ featureKey: f.featureKey, enabled: f.enabled })) || [],
      limits: initialData.limits?.map(l => ({ key: l.key, value: l.value })) || [],
    } : {
      name: '', slug: '', currency: 'USD', status: 'ACTIVE', features: [], limits: []
    }
  });

  const { fields: featureFields, append: appendFeature, remove: removeFeature } = useFieldArray({
    control: form.control,
    name: "features"
  });

  const { fields: limitFields, append: appendLimit, remove: removeLimit } = useFieldArray({
    control: form.control,
    name: "limits"
  });

  const onSubmit = async (values: PlanFormValues) => {
    setError(null);
    try {
      const isEditing = !!initialData;
      const url = isEditing ? `/api/v1/admin/plans/${initialData.id}` : `/api/v1/admin/plans`;
      
      // We don't want to call next api directly, we need to proxy through our BFF but since our API client uses cookies implicitly we can just call it from a Server Action or pass it to our local route handler. 
      // Actually we'll call our BFF to avoid CORS if not on same origin, but in our `fetchApi` client we use absolute API_URL and `credentials: 'include'`. But we can't easily do `credentials: 'include'` for HttpOnly cookies cross origin if Next.js and NestJS are on different ports. Wait, our `fetchApi` is a server utility! We cannot call `fetchApi` from a Client Component directly if it uses `next/headers`.
      // Let's implement a Server Action wrapper instead.
      const res = await savePlan(isEditing ? initialData.id : null, values);
      if (res.error) {
        setError(res.error);
        return;
      }
      
      router.push('/admin/plans');
      router.refresh();
    } catch (err: any) {
      setError(err.message || 'An unexpected error occurred.');
    }
  };

  return (
    <form onSubmit={form.handleSubmit(onSubmit as any)} className="space-y-8 bg-white p-6 shadow-sm ring-1 ring-gray-900/5 sm:rounded-xl">
      {error && <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{error}</div>}
      
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
        <div className="sm:col-span-2">
          <label className="block text-sm font-medium text-gray-700">Name</label>
          <input {...form.register('name')} className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" />
          {form.formState.errors.name && <p className="mt-1 text-sm text-red-600">{form.formState.errors.name.message}</p>}
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Slug</label>
          <input {...form.register('slug')} className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Status</label>
          <select {...form.register('status')} className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500">
            <option value="ACTIVE">Active</option>
            <option value="INACTIVE">Inactive</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Monthly Price</label>
          <input type="number" step="0.01" {...form.register('monthlyPrice')} className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700">Yearly Price</label>
          <input type="number" step="0.01" {...form.register('yearlyPrice')} className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" />
        </div>
      </div>

      <div className="border-t pt-6">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-medium text-gray-900">Features</h3>
          <button type="button" onClick={() => appendFeature({ featureKey: '', enabled: true })} className="inline-flex items-center text-sm font-medium text-blue-600 hover:text-blue-500">
            <Plus className="w-4 h-4 mr-1" /> Add Feature
          </button>
        </div>
        <div className="mt-4 space-y-4">
          {featureFields.map((field, index) => (
            <div key={field.id} className="flex items-center gap-4">
              <input {...form.register(`features.${index}.featureKey` as const)} placeholder="Feature Key" className="block flex-1 rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" />
              <label className="flex items-center gap-2 text-sm text-gray-700">
                <input type="checkbox" {...form.register(`features.${index}.enabled` as const)} className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500" />
                Enabled
              </label>
              <button type="button" onClick={() => removeFeature(index)} className="text-red-500 hover:text-red-700"><Trash2 className="w-4 h-4" /></button>
            </div>
          ))}
        </div>
      </div>

      <div className="border-t pt-6">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-medium text-gray-900">Limits</h3>
          <button type="button" onClick={() => appendLimit({ key: '', value: 0 })} className="inline-flex items-center text-sm font-medium text-blue-600 hover:text-blue-500">
            <Plus className="w-4 h-4 mr-1" /> Add Limit
          </button>
        </div>
        <div className="mt-4 space-y-4">
          {limitFields.map((field, index) => (
            <div key={field.id} className="flex items-center gap-4">
              <input {...form.register(`limits.${index}.key` as const)} placeholder="Limit Key" className="block flex-1 rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" />
              <input type="number" {...form.register(`limits.${index}.value` as const)} placeholder="Value" className="block w-32 rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" />
              <button type="button" onClick={() => removeLimit(index)} className="text-red-500 hover:text-red-700"><Trash2 className="w-4 h-4" /></button>
            </div>
          ))}
        </div>
      </div>

      <div className="border-t pt-6 flex justify-end">
        <button
          type="submit"
          disabled={form.formState.isSubmitting}
          className="rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 disabled:opacity-50"
        >
          {form.formState.isSubmitting ? 'Saving...' : 'Save Plan'}
        </button>
      </div>
    </form>
  );
}

// Server Action Implementation
import { savePlan } from './actions';
