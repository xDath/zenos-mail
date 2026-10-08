// POST /api/logout
import { destroySession } from '../../lib/session'

export default function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' })
  const cookie = destroySession()
  res.setHeader('Set-Cookie', `${cookie.name}=; Max-Age=0; Path=/`)
  return res.status(200).json({ success: true })
}
