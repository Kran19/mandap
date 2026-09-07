import { NextResponse } from 'next/server';
import { setAuthCookies } from '@/lib/api/client';

const API_URL = process.env.API_URL || 'http://localhost:3000';

export async function POST(request: Request) {
  try {
    const body = await request.json();

    const res = await fetch(`${API_URL}/api/v1/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = await res.json();

    if (!res.ok) {
      return NextResponse.json(data, { status: res.status });
    }

    // Set the cookies securely
    await setAuthCookies(data.accessToken, data.refreshToken);

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ message: error.message || 'Internal Server Error' }, { status: 500 });
  }
}
