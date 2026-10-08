import { databaseConfigured, listMessages } from '../../../lib/mail-store'
import { resend } from '../../../lib/resend'

export default async function handler(req, res) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' })
  res.setHeader('Cache-Control', 'no-store')

  const query = typeof req.query.q === 'string' ? req.query.q.slice(0, 200) : ''
  const domain = typeof req.query.domain === 'string' ? req.query.domain.slice(0, 253) : ''
  const direction = req.query.direction === 'outbound' ? 'outbound' : 'inbound'
  const limit = Math.min(Number(req.query.limit) || 50, 100)

  try {
    if (databaseConfigured()) {
      const data = await listMessages({ query, domain, direction, limit })
      return res.status(200).json({ success: true, data, source: 'archive' })
    }

    if (direction === 'outbound') {
      return res.status(200).json({ success: true, data: [], source: 'resend' })
    }
    const result = await resend(`/emails/receiving?limit=${limit}`)
    if (!result.ok) return res.status(result.status).json({ success: false, error: result.error })
    const items = result.data?.data || result.data || []
    const normalizedQuery = query.trim().toLowerCase()
    const normalizedDomain = domain.trim().toLowerCase()
    const data = items.filter(email => {
      const recipients = Array.isArray(email.to) ? email.to : [email.to].filter(Boolean)
      const matchesDomain = !normalizedDomain || recipients.some(address => address?.toLowerCase().endsWith(`@${normalizedDomain}`))
      const haystack = [email.from, ...recipients, email.subject].filter(Boolean).join('\n').toLowerCase()
      return matchesDomain && (!normalizedQuery || haystack.includes(normalizedQuery))
    })
    return res.status(200).json({ success: true, data, source: 'resend' })
  } catch (error) {
    console.error('Mail list error:', error)
    return res.status(500).json({ success: false, error: 'Gagal memuat arsip email.' })
  }
}
