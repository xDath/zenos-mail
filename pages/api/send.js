// POST /api/send
// Supports attachments (base64), dynamic sender overrides

export const config = {
  api: {
    bodyParser: {
      sizeLimit: '10mb',
    },
  },
}

async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' })

  const { to, cc, bcc, subject, html, text, attachments, sender_email, sender_name, reply_to } = req.body

  const apiKey = process.env.RESEND_API_KEY
  if (!apiKey) return res.status(500).json({ success: false, error: 'No API key configured' })

  const fromEmail = sender_email || process.env.SENDER_EMAIL || 'onboarding@resend.dev'
  const fromName = sender_name || process.env.SENDER_NAME || 'Zenos Mail'
  const replyTo = reply_to || process.env.REPLY_TO

  const payload = {
    from: `${fromName} <${fromEmail}>`,
    to: Array.isArray(to) ? to : [to],
    subject,
  }

  if (replyTo) payload.reply_to = replyTo
  if (html) payload.html = html
  else payload.text = text || ''

  if (cc?.length) payload.cc = cc
  if (bcc?.length) payload.bcc = bcc

  // Handle file attachments
  if (attachments?.length) {
    payload.attachments = attachments.map(a => ({
      filename: a.filename,
      content: a.content,
    }))
  }

  try {
    const fetchRes = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    })
    const data = await fetchRes.json()

    if (!fetchRes.ok) {
      const errMsg = data.message || JSON.stringify(data)
      return res.status(400).json({ success: false, error: errMsg })
    }

    return res.status(200).json({ success: true, id: data.id })
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message })
  }
}

export default handler
