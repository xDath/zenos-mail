// POST /api/login
import { createSession } from '../../lib/session'

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' })

  const { password } = req.body
  const validPassword = process.env.DASHBOARD_PASSWORD || 'zenos2024'

  if (!password || password !== validPassword) {
    return res.status(401).json({ success: false, error: 'Invalid password' })
  }

  const cookie = await createSession()
  res.setHeader('Set-Cookie', `${cookie.name}=${cookie.value}; HttpOnly; Secure; SameSite=Lax; Max-Age=${cookie.maxAge}; Path=/`)
  return res.status(200).json({ success: true })
}
