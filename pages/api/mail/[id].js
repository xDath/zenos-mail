import { databaseConfigured, getMessage, markMessageRead } from '../../../lib/mail-store'
import { resend } from '../../../lib/resend'

async function addAttachmentDownloads(message, id) {
  if (!Array.isArray(message?.attachments) || !message.attachments.length) return message
  const result = await resend(`/emails/receiving/${id}/attachments?limit=100`)
  if (!result.ok) return message
  const attachments = result.data?.data || result.data
  if (!Array.isArray(attachments)) return message
  return { ...message, attachments }
}

export default async function handler(req, res) {
  const { id } = req.query
  if (typeof id !== 'string' || !/^[0-9a-z-]{6,128}$/i.test(id)) {
    return res.status(400).json({ success: false, error: 'ID email tidak valid.' })
  }
  res.setHeader('Cache-Control', 'no-store')

  try {
    if (req.method === 'PATCH') {
      if (!databaseConfigured()) return res.status(200).json({ success: true })
      return res.status((await markMessageRead(id)) ? 200 : 404).json({ success: true })
    }
    if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' })

    if (databaseConfigured()) {
      const message = await getMessage(id)
      if (message) {
        const data = message.direction === 'inbound'
          ? await addAttachmentDownloads(message, id)
          : message
        return res.status(200).json({ success: true, data, source: 'archive' })
      }
    }
    const result = await resend(`/emails/receiving/${id}`)
    if (!result.ok) {
      return res.status(result.status).json({ success: false, error: result.error })
    }
    const data = await addAttachmentDownloads(result.data, id)
    return res.status(result.status).json({ success: true, data, source: 'resend' })
  } catch (error) {
    console.error('Mail detail error:', error)
    return res.status(500).json({ success: false, error: 'Gagal memuat email.' })
  }
}
