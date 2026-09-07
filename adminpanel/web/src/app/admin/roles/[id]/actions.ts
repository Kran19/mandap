'use server';

import { fetchApi } from '@/lib/api/client';
import { revalidatePath } from 'next/cache';

export async function saveRole(id: string | null, data: any) {
  try {
    if (id) {
      await fetchApi(`/api/v1/admin/roles/${id}`, {
        method: 'PATCH',
        body: JSON.stringify(data),
      });
      revalidatePath(`/admin/roles/${id}`);
    } else {
      await fetchApi(`/api/v1/admin/roles`, {
        method: 'POST',
        body: JSON.stringify(data),
      });
    }
    
    revalidatePath('/admin/roles');
    return { success: true };
  } catch (error: any) {
    if (error.status === 403) {
      return { error: 'You do not have permission to modify roles.' };
    }
    return { error: error.message || 'Failed to save role.' };
  }
}
