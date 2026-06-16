// POST /api/send
import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' })

  const { to, cc, bcc, subject, html, text } = req.body
  const senderEmail = process.env.SENDER_EMAIL || 'onboarding@resend.dev'
  const senderName = process.env.SENDER_NAME || 'Zenos Mail'
  const replyTo = process.env.REPLY_TO

  const payload = {
    from: `${senderName} <${senderEmail}>`,
    to: Array.isArray(to) ? to : [to],
    subject,
    reply_to: replyTo,
  }

  if (html) payload.html = html
  else payload.text = text || ''
  if (cc?.length) payload.cc = cc
  if (bcc?.length) payload.bcc = bcc

  try {
    const { data, error } = await resend.emails.send(payload)
    if (error) return res.status(400).json({ success: false, error: error.message || JSON.stringify(error) })
    return res.status(200).json({ success: true, id: data.id })
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message })
  }
}
