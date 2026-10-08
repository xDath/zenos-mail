import { resend, sendingReady, validEmail } from '../../lib/resend'

export const config = { api: { bodyParser: { sizeLimit: '10mb' } } }

function addresses(value) {
  return Array.isArray(value) && value.length <= 50 && value.every(validEmail)
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' })
  const { to, cc = [], bcc = [], subject, html, text, attachments = [], sender_email, sender_name, reply_to } = req.body || {}
  const fromEmail = sender_email || process.env.SENDER_EMAIL
  const fromName = sender_name || process.env.SENDER_NAME || 'Zenos Mail'
  const replyTo = reply_to || process.env.REPLY_TO

  if (!validEmail(fromEmail) || !addresses(to) || !to.length || !addresses(cc) || !addresses(bcc) ||
      typeof subject !== 'string' || !subject.trim() || subject.length > 998 ||
      ((typeof text !== 'string' || !text.trim()) && (typeof html !== 'string' || !html.trim())) ||
      typeof fromName !== 'string' || !fromName.trim() || /[\r\n<>]/.test(fromName) || fromName.length > 100 ||
      (replyTo && !validEmail(replyTo)) || !Array.isArray(attachments) || attachments.length > 10 ||
      !attachments.every(a => a && typeof a.filename === 'string' && a.filename.length <= 255 &&
        typeof a.content === 'string' && /^[A-Za-z0-9+/=]+$/.test(a.content))) {
    return res.status(400).json({ success: false, error: 'Data email tidak valid. Periksa pengirim, penerima, isi, dan lampiran.' })
  }

  const domains = await resend('/domains')
  if (!domains.ok) return res.status(domains.status).json({ success: false, error: domains.error })
  const senderDomain = fromEmail.split('@')[1].toLowerCase()
  const selected = domains.data?.data?.find(d => d.name?.toLowerCase() === senderDomain)
  const domain = selected?.status === 'partially_verified'
    ? (await resend(`/domains/${selected.id}`)).data
    : selected
  if (!sendingReady(domain)) {
    return res.status(400).json({ success: false, error: `Domain ${senderDomain} belum terverifikasi untuk mengirim.` })
  }

  const payload = {
    from: `${fromName.replace(/"/g, '')} <${fromEmail}>`,
    to, cc, bcc, subject: subject.trim(),
    ...(html?.trim() ? { html } : { text }),
    ...(replyTo ? { reply_to: replyTo } : {}),
    ...(attachments.length ? { attachments } : {}),
  }
  const result = await resend('/emails', { method: 'POST', body: JSON.stringify(payload) })
  return res.status(result.status).json(result.ok
    ? { success: true, id: result.data.id }
    : { success: false, error: result.error })
}
