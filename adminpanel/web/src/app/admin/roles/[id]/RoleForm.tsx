'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { AdminRoleModel } from '@/types';
import { saveRole } from './actions';

const roleSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  description: z.string().optional(),
  isActive: z.boolean().default(true),
  permissions: z.array(z.string()).default([]),
});

type RoleFormValues = z.infer<typeof roleSchema>;

interface RoleFormProps {
  initialData?: AdminRoleModel;
  allPermissions: any[];
}

export default function RoleForm({ initialData, allPermissions }: RoleFormProps) {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);

  const form = useForm<RoleFormValues>({
    resolver: zodResolver(roleSchema) as any,
    defaultValues: initialData ? {
      name: initialData.name,
      description: initialData.description || '',
      isActive: initialData.isActive,
      permissions: initialData.permissions?.map(p => p.action) || [],
    } : {
      name: '', description: '', isActive: true, permissions: []
    }
  });

  const onSubmit = async (values: RoleFormValues) => {
    setError(null);
    try {
      const isEditing = !!initialData;
      const res = await saveRole(isEditing ? initialData.id : null, values);
      if (res.error) {
        setError(res.error);
        return;
      }
      
      router.push('/admin/roles');
      router.refresh();
    } catch (err: any) {
      setError(err.message || 'An unexpected error occurred.');
    }
  };

  const selectedPermissions = form.watch('permissions');

  const togglePermission = (action: string) => {
    if (selectedPermissions.includes(action)) {
      form.setValue('permissions', selectedPermissions.filter(p => p !== action));
    } else {
      form.setValue('permissions', [...selectedPermissions, action]);
    }
  };

  return (
    <form onSubmit={form.handleSubmit(onSubmit as any)} className="space-y-6 bg-white p-6 shadow-sm ring-1 ring-gray-900/5 sm:rounded-xl">
      {error && <div className="rounded-md bg-red-50 p-4 text-sm text-red-800">{error}</div>}
      
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
        <div className="sm:col-span-2">
          <label className="block text-sm font-medium text-gray-700">Role Name (Must be valid AdminRole enum if strict)</label>
          <input {...form.register('name')} className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" disabled={!!initialData} />
          {form.formState.errors.name && <p className="mt-1 text-sm text-red-600">{form.formState.errors.name.message}</p>}
        </div>

        <div className="sm:col-span-2">
          <label className="block text-sm font-medium text-gray-700">Description</label>
          <input {...form.register('description')} className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500" />
        </div>

        <div className="sm:col-span-2 flex items-center gap-2">
          <input type="checkbox" {...form.register('isActive')} className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500" />
          <label className="text-sm font-medium text-gray-700">Is Active</label>
        </div>
      </div>

      <div className="border-t pt-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Permissions</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {allPermissions.map((perm) => (
            <label key={perm} className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={selectedPermissions.includes(perm)}
                onChange={() => togglePermission(perm)}
                className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span className="text-sm text-gray-700">{perm}</span>
            </label>
          ))}
        </div>
      </div>

      <div className="border-t pt-6 flex justify-end">
        <button
          type="submit"
          disabled={form.formState.isSubmitting}
          className="rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 disabled:opacity-50"
        >
          {form.formState.isSubmitting ? 'Saving...' : 'Save Role'}
        </button>
      </div>
    </form>
  );
}
