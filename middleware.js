import { NextResponse } from 'next/server'
import { validateSession } from './lib/session'

const SESSION_COOKIE = 'zenos_session'

export async function middleware(req) {
  const { pathname } = req.nextUrl

  // Public routes
  if (pathname === '/login' || pathname === '/api/login' || pathname === '/api/logout' || pathname.startsWith('/api/webhook') || pathname === '/favicon.ico') {
    return NextResponse.next()
  }

  // API routes protected
  if (pathname.startsWith('/api/') && pathname !== '/api/login') {
    const sessionToken = req.cookies.get(SESSION_COOKIE)?.value
    if (!sessionToken || !(await validateSession(sessionToken))) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }
    return NextResponse.next()
  }

  // Page routes protected
  const sessionToken = req.cookies.get(SESSION_COOKIE)?.value
  if (!sessionToken || !(await validateSession(sessionToken))) {
    const loginUrl = new URL('/login', req.url)
    loginUrl.searchParams.set('redirect', pathname)
    return NextResponse.redirect(loginUrl)
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
