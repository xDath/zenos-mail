import { resend, respond } from '../../lib/resend'

// GET /api/inbox — list received emails via Resend API
export default async function handler(req, res) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' })
  res.setHeader('Cache-Control', 'no-store')
  return respond(res, await resend('/emails/receiving'))
}
