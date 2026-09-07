import { NextResponse } from 'next/server';
import { clearAuthCookies, fetchApi } from '@/lib/api/client';
import { cookies } from 'next/headers';

export async function POST(request: Request) {
  try {
    const cookieStore = await cookies();
    const refreshToken = cookieStore.get('refreshToken')?.value;

    if (refreshToken) {
      // Attempt to tell the backend to invalidate the refresh session
      try {
        await fetchApi('/api/v1/auth/logout', {
          method: 'POST',
          body: JSON.stringify({ refreshToken }),
        });
      } catch (e) {
        // We still want to clear local cookies even if backend fails
      }
    }

    await clearAuthCookies();
    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ message: error.message || 'Internal Server Error' }, { status: 500 });
  }
}
