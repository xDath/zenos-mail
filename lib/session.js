import { SignJWT, jwtVerify } from 'jose'

const SESSION_SECRET = new TextEncoder().encode(process.env.JWT_SECRET || '')
const SESSION_COOKIE = 'zenos_session'
const WEB_SESSION_TTL = 24 * 60 * 60
const MOBILE_SESSION_TTL = 30 * 24 * 60 * 60

export async function createSession({ mobile = false } = {}) {
  const ttl = mobile ? MOBILE_SESSION_TTL : WEB_SESSION_TTL
  const token = await new SignJWT({})
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(`${ttl}s`)
    .sign(SESSION_SECRET)

  return {
    name: SESSION_COOKIE,
    value: token,
    httpOnly: true,
    secure: true,
    sameSite: 'lax',
    maxAge: ttl,
    path: '/',
  }
}

export function destroySession() {
  return { name: SESSION_COOKIE, value: '', maxAge: 0, path: '/' }
}

export async function validateSession(token) {
  try {
    if (!process.env.JWT_SECRET) return false
    await jwtVerify(token, SESSION_SECRET)
    return true
  } catch {
    return false
  }
}
