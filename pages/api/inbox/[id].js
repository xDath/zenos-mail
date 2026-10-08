import { resend, respond } from '../../../lib/resend'

// GET /api/inbox/[id] — fetch single received email with full content
export default async function handler(req, res) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' })

  const { id } = req.query
  if (typeof id !== 'string' || !/^[0-9a-f-]{36}$/i.test(id)) return res.status(400).json({ success: false, error: 'ID email tidak valid.' })
  res.setHeader('Cache-Control', 'no-store')
  return respond(res, await resend(`/emails/receiving/${id}`))
}
