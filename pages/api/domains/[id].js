import { resend, respond } from '../../../lib/resend'

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store')
  const { id } = req.query
  if (typeof id !== 'string' || !/^[0-9a-f-]{36}$/i.test(id)) {
    return res.status(400).json({ success: false, error: 'ID domain tidak valid.' })
  }
  if (req.method === 'GET') return respond(res, await resend(`/domains/${id}`))
  if (req.method === 'POST') return respond(res, await resend(`/domains/${id}/verify`, { method: 'POST' }))
  if (req.method === 'PATCH') {
    if (typeof req.body?.receiving !== 'boolean') {
      return res.status(400).json({ success: false, error: 'Status penerimaan tidak valid.' })
    }
    return respond(res, await resend(`/domains/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ capabilities: { receiving: req.body.receiving ? 'enabled' : 'disabled' } }),
    }))
  }
  return res.status(405).json({ error: 'Method not allowed' })
}
