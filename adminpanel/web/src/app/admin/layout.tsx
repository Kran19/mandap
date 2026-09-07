import { fetchApi } from '@/lib/api/client';
import { CurrentAdminUser } from '@/types';
import AdminShell from '@/components/layout/AdminShell';

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  let user: CurrentAdminUser | null = null;
  try {
    user = await fetchApi<CurrentAdminUser>('/api/v1/admin/me');
  } catch (error) {
    // If we fail to fetch /me, the user might not be an admin or token is invalid
    // The middleware handles basic auth redirects, but here we can just pass null
    // or let the shell handle the display.
  }

  return (
    <div className="flex h-screen bg-gray-50 overflow-hidden">
      <AdminShell user={user}>
        {children}
      </AdminShell>
    </div>
  );
}
