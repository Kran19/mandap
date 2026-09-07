'use server';

import { fetchApi } from '@/lib/api/client';
import { revalidatePath } from 'next/cache';

export async function removeMember(organizationId: string, userId: string) {
  try {
    await fetchApi(`/api/v1/admin/organizations/${organizationId}/members/${userId}`, {
      method: 'DELETE',
    });
    
    revalidatePath(`/admin/organizations/${organizationId}`);
    return { success: true };
  } catch (error: any) {
    if (error.status === 403) {
      return { error: 'You do not have permission to remove members.' };
    }
    return { error: error.message || 'Failed to remove member.' };
  }
}

export async function updateMemberRole(organizationId: string, userId: string, role: string) {
  try {
    await fetchApi(`/api/v1/admin/organizations/${organizationId}/members/${userId}`, {
      method: 'PATCH',
      body: JSON.stringify({ role }),
    });
    
    revalidatePath(`/admin/organizations/${organizationId}`);
    return { success: true };
  } catch (error: any) {
    if (error.status === 403) {
      return { error: 'You do not have permission to update members.' };
    }
    return { error: error.message || 'Failed to update member role.' };
  }
}
