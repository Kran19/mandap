import { Metadata } from 'next';
import { fetchApi } from '@/lib/api/client';
import { CurrentAdminUser } from '@/types';
import SettingsForm from './SettingsForm';

export const metadata: Metadata = {
  title: 'Settings | Admin Panel',
};

export default async function SettingsPage() {
  let user: CurrentAdminUser | null = null;
  let errorMsg: string | null = null;

  try {
    user = await fetchApi<CurrentAdminUser>('/api/v1/admin/me');
  } catch (error: any) {
    errorMsg = error.message || 'Failed to load user settings.';
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Account Settings</h1>
        <p className="mt-1 text-sm text-gray-500">
          Manage your account credentials, email, phone number, and security preferences.
        </p>
      </div>

      {errorMsg ? (
        <div className="rounded-md bg-red-50 p-4">
          <p className="text-sm text-red-800">{errorMsg}</p>
        </div>
      ) : user ? (
        <SettingsForm user={user} />
      ) : null}
    </div>
  );
}
