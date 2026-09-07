'use server';

import { fetchApi } from '@/lib/api/client';
import { revalidatePath } from 'next/cache';

export async function updateUserStatus(userId: string, status: string) {
  try {
    await fetchApi(`/api/v1/admin/users/${userId}`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
    
    revalidatePath('/admin/users');
    revalidatePath(`/admin/users/${userId}`);
    return { success: true };
  } catch (error: any) {
    if (error.status === 403) {
      return { error: 'You do not have permission to modify users.' };
    }
    return { error: error.message || 'Failed to update user status.' };
  }
}
