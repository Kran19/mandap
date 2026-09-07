import { Metadata } from 'next';
import { fetchApi } from '@/lib/api/client';

export const metadata: Metadata = {
  title: 'Subscriptions | Admin Panel',
};

export default async function SubscriptionsPage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Subscriptions</h1>
      </div>
      <div className="bg-white p-6 rounded-lg shadow text-gray-500">
        Subscriptions data table implementation placeholder.
      </div>
    </div>
  );
}
