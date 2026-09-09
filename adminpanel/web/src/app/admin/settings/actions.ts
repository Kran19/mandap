'use server';

import { fetchApi } from '@/lib/api/client';
import { revalidatePath } from 'next/cache';

export interface UpdateProfileInput {
  email?: string;
  phone?: string;
  firstName?: string;
  lastName?: string;
}

export interface ChangePasswordInput {
  currentPassword: string;
  newPassword: string;
}

export async function updateAdminProfile(data: UpdateProfileInput) {
  try {
    const updated = await fetchApi('/api/v1/admin/me/profile', {
      method: 'PATCH',
      body: JSON.stringify(data),
    });

    revalidatePath('/admin');
    revalidatePath('/admin/settings');
    return { success: true, user: updated };
  } catch (error: any) {
    return {
      error: error.message || 'Failed to update profile.',
    };
  }
}

export async function changeAdminPassword(data: ChangePasswordInput) {
  try {
    const res = await fetchApi('/api/v1/admin/me/change-password', {
      method: 'POST',
      body: JSON.stringify(data),
    });

    revalidatePath('/admin/settings');
    return { success: true, message: (res as any)?.message || 'Password updated successfully.' };
  } catch (error: any) {
    return {
      error: error.message || 'Failed to change password.',
    };
  }
}
