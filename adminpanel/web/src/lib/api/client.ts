import { cookies } from 'next/headers';
import { ApiError } from '@/types';

// The server-side API_URL defaults to http://localhost:3000 but can be configured in .env
const API_URL = process.env.API_URL || 'http://localhost:3000';

class ApiException extends Error {
  public status: number;
  public details?: any;

  constructor(error: ApiError) {
    super(error.message);
    this.status = error.status;
    this.details = error.details;
  }
}

async function getAccessToken() {
  const cookieStore = await cookies();
  return cookieStore.get('accessToken')?.value;
}

async function getRefreshToken() {
  const cookieStore = await cookies();
  return cookieStore.get('refreshToken')?.value;
}

export async function clearAuthCookies() {
  try {
    const cookieStore = await cookies();
    cookieStore.delete('accessToken');
    cookieStore.delete('refreshToken');
  } catch (e) {
    // Ignore error in Server Components where cookies are read-only
  }
}

export async function setAuthCookies(accessToken: string, refreshToken: string) {
  try {
    const cookieStore = await cookies();
    cookieStore.set('accessToken', accessToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
    });
    cookieStore.set('refreshToken', refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
    });
  } catch (e) {
    // Ignore error in Server Components where cookies are read-only
  }
}

// Global flag to prevent concurrent refresh races (basic implementation for server-side fetches)
let isRefreshing = false;
let refreshPromise: Promise<boolean> | null = null;

async function handleTokenRefresh(): Promise<boolean> {
  if (isRefreshing && refreshPromise) {
    return refreshPromise;
  }

  isRefreshing = true;
  refreshPromise = (async () => {
    try {
      const refreshToken = await getRefreshToken();
      if (!refreshToken) {
        return false;
      }

      const res = await fetch(`${API_URL}/api/v1/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken }),
      });

      if (!res.ok) {
        await clearAuthCookies();
        return false;
      }

      const data = await res.json();
      await setAuthCookies(data.accessToken, data.refreshToken);
      return true;
    } catch (error) {
      await clearAuthCookies();
      return false;
    } finally {
      isRefreshing = false;
      refreshPromise = null;
    }
  })();

  return refreshPromise;
}

export async function fetchApi<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  let token = await getAccessToken();

  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  } as Record<string, string>;

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  let res = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers,
  });

  if (res.status === 401 && token) {
    // Attempt to refresh
    const refreshed = await handleTokenRefresh();
    if (refreshed) {
      // Retry with new token
      token = await getAccessToken();
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
        res = await fetch(`${API_URL}${endpoint}`, {
          ...options,
          headers,
        });
      }
    }
  }

  if (!res.ok) {
    let errorData: ApiError;
    try {
      errorData = await res.json();
    } catch {
      errorData = { status: res.status, message: res.statusText };
    }
    throw new ApiException({
      status: res.status,
      message: errorData.message || res.statusText,
      details: errorData,
    });
  }

  // Support empty responses (e.g., 204 No Content)
  const text = await res.text();
  return text ? JSON.parse(text) : ({} as T);
}
