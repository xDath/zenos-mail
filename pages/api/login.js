// POST /api/login
import { createSession } from '../../lib/session'
import { timingSafeEqual } from 'node:crypto'

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' })

  const { password, client } = req.body || {}
  const validPassword = process.env.DASHBOARD_PASSWORD
  if (!validPassword || !process.env.JWT_SECRET) {
    return res.status(503).json({ success: false, error: 'Login belum dikonfigurasi di server.' })
  }

  const submitted = Buffer.from(typeof password === 'string' ? password : '')
  const expected = Buffer.from(validPassword)
  if (submitted.length !== expected.length || !timingSafeEqual(submitted, expected)) {
    return res.status(401).json({ success: false, error: 'Invalid password' })
  }

  const mobile = client === 'android'
  const cookie = await createSession({ mobile })
  res.setHeader('Set-Cookie', `${cookie.name}=${cookie.value}; HttpOnly; Secure; SameSite=Lax; Max-Age=${cookie.maxAge}; Path=/`)
  return res.status(200).json({ success: true, ...(mobile ? { token: cookie.value } : {}) })
}
