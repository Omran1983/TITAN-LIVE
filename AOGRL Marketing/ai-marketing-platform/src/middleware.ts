import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

// Simple middleware that allows all requests without authentication
export function middleware(request: NextRequest) {
  // Allow all requests to proceed without authentication
  return NextResponse.next()
}

// Configure which paths the middleware should run on
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
}