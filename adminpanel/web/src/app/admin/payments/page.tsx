import { Metadata } from 'next';
import { createRefundAction } from './actions';
import { fetchApi } from '@/lib/api/client';
import { PaginatedResponse, CurrentAdminUser } from '@/types';
import { hasPermission, AdminPermissions } from '@/lib/permissions/helpers';

export const metadata: Metadata = {
  title: 'Payments | Admin Panel',
};

export default async function PaymentsPage() {
  let user: CurrentAdminUser | null = null;
  try {
    user = await fetchApi<CurrentAdminUser>('/api/v1/admin/me');
  } catch (e) {
    // handled by middleware
  }
  const canRefund = user ? hasPermission(user, AdminPermissions.REFUNDS_CREATE) : false;

  let errorMsg = null;
  let payments: any[] = [];

  try {
    const response = await fetchApi<PaginatedResponse<any>>(`/api/v1/admin/payments`);
    payments = response.data;
  } catch (error: any) {
    errorMsg = error.message || "Failed to load payments.";
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Payments</h1>
      </div>

      {errorMsg ? (
        <div className="rounded-md bg-red-50 p-4">
          <p className="text-sm text-red-800">{errorMsg}</p>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {payments.map((p) => (
                <tr key={p.id}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{p.id}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{p.amount} {p.currency}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{p.status}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    {canRefund && p.status === 'SUCCESSFUL' && (
                      <form action={async () => {
                        'use server';
                        await createRefundAction(p.id, parseFloat(p.amount));
                      }}>
                        <button type="submit" className="text-indigo-600 hover:text-indigo-900">
                          Refund Full
                        </button>
                      </form>
                    )}
                  </td>
                </tr>
              ))}
              {payments.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-6 py-4 text-center text-sm text-gray-500">No payments found</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
