import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Orders | Admin Panel',
};

export default async function OrdersPage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Orders</h1>
      </div>
      <div className="bg-white p-6 rounded-lg shadow text-gray-500">
        Orders data table implementation placeholder.
      </div>
    </div>
  );
}
