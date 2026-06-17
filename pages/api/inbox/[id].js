// GET /api/inbox/[id] — fetch single received email with full content
export default async function handler(req, res) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' })

  const { id } = req.query
  if (!id) return res.status(400).json({ success: false, error: 'Missing email ID' })

  try {
    const resp = await fetch(`https://api.resend.com/emails/receiving/${id}`, {
      headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}` },
    })
    const data = await resp.json()

    if (!resp.ok) return res.status(400).json({ success: false, error: data.message || `HTTP ${resp.status}` })
    return res.status(200).json({ success: true, data })
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message })
  }
}
