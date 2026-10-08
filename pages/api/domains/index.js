import { resend, respond, validDomain } from '../../../lib/resend'

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store')
  if (req.method === 'GET') return respond(res, await resend('/domains'))
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' })

  const name = typeof req.body?.name === 'string' ? req.body.name.trim().toLowerCase() : ''
  if (!validDomain(name)) return res.status(400).json({ success: false, error: 'Masukkan nama domain yang valid.' })
  return respond(res, await resend('/domains', { method: 'POST', body: JSON.stringify({ name }) }))
}
