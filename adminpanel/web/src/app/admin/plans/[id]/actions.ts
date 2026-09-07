'use server';

import { fetchApi } from '@/lib/api/client';
import { revalidatePath } from 'next/cache';

export async function savePlan(id: string | null, data: any) {
  try {
    if (id) {
      await fetchApi(`/api/v1/admin/plans/${id}`, {
        method: 'PATCH',
        body: JSON.stringify(data),
      });
      revalidatePath(`/admin/plans/${id}`);
    } else {
      await fetchApi(`/api/v1/admin/plans`, {
        method: 'POST',
        body: JSON.stringify(data),
      });
    }
    
    revalidatePath('/admin/plans');
    return { success: true };
  } catch (error: any) {
    if (error.status === 403) {
      return { error: 'You do not have permission to modify plans.' };
    }
    return { error: error.message || 'Failed to save plan.' };
  }
}
