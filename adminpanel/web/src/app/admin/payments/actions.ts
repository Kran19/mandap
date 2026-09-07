'use server';

import { fetchApi } from '@/lib/api/client';
import { revalidatePath } from 'next/cache';

export async function createRefundAction(paymentId: string, amount: number, reason?: string) {
  try {
    await fetchApi(`/api/v1/admin/payments/${paymentId}/refund`, {
      method: 'POST',
      body: JSON.stringify({ amount, reason }),
    });
    
    revalidatePath('/admin/payments');
    revalidatePath('/admin/refunds');
    
    return { success: true };
  } catch (error: any) {
    return { success: false, error: error.message || 'Failed to create refund' };
  }
}
