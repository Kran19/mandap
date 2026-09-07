'use server';

import { fetchApi } from '@/lib/api/client';
import { revalidatePath } from 'next/cache';

export async function saveFeatureFlag(id: string | null, data: any) {
  try {
    if (id) {
      await fetchApi(`/api/v1/admin/feature-flags/${id}`, {
        method: 'PATCH',
        body: JSON.stringify(data),
      });
      revalidatePath(`/admin/feature-flags/${id}`);
    } else {
      await fetchApi(`/api/v1/admin/feature-flags`, {
        method: 'POST',
        body: JSON.stringify(data),
      });
    }
    
    revalidatePath('/admin/feature-flags');
    return { success: true };
  } catch (error: any) {
    if (error.status === 403) {
      return { error: 'You do not have permission to modify feature flags.' };
    }
    return { error: error.message || 'Failed to save feature flag.' };
  }
}
