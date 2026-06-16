// POST /api/logout
import { destroySession } from '../../lib/session'

export default function handler(req, res) {
  const cookie = destroySession()
  res.setHeader('Set-Cookie', `${cookie.name}=; Max-Age=0; Path=/`)
  return res.status(200).json({ success: true })
}
