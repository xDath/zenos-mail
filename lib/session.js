import { SignJWT, jwtVerify } from 'jose'

const SESSION_SECRET = new TextEncoder().encode(process.env.JWT_SECRET || 'change-me-in-vercel-env')
const SESSION_COOKIE = 'zenos_session'
const SESSION_TTL = 24 * 60 * 60

export async function createSession() {
  const token = await new SignJWT({})
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(`${SESSION_TTL}s`)
    .sign(SESSION_SECRET)

  return {
    name: SESSION_COOKIE,
    value: token,
    httpOnly: true,
    secure: true,
    sameSite: 'lax',
    maxAge: SESSION_TTL,
    path: '/',
  }
}

export function destroySession() {
  return { name: SESSION_COOKIE, value: '', maxAge: 0, path: '/' }
}

export async function validateSession(token) {
  try {
    await jwtVerify(token, SESSION_SECRET)
    return true
  } catch {
    return false
  }
}
