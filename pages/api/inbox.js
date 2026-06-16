// GET /api/inbox — list received emails via Resend API
export default async function handler(req, res) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' })

  try {
    const resp = await fetch('https://api.resend.com/emails/receiving', {
      headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}` },
    })
    const data = await resp.json()
    if (!resp.ok) return res.status(400).json({ success: false, error: data.message || `HTTP ${resp.status}` })
    return res.status(200).json({ success: true, data })
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message })
  }
}
