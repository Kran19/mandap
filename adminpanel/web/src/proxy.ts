import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Protected routes require authentication
const isProtectedRoute = (path: string) => path.startsWith('/admin');

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  const token = request.cookies.get('accessToken')?.value;

  if (isProtectedRoute(pathname) && !token) {
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    // Optionally preserve intended destination:
    // url.searchParams.set('callbackUrl', encodeURI(pathname));
    return NextResponse.redirect(url);
  }

  // Prevent authenticated users from visiting the login page
  if (pathname === '/login' && token) {
    const url = request.nextUrl.clone();
    url.pathname = '/admin';
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
};
