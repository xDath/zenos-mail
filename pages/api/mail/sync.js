import { archiveMessage, databaseConfigured } from '../../../lib/mail-store'
import { resend } from '../../../lib/resend'

async function batches(items, size, worker) {
  const results = []
  for (let index = 0; index < items.length; index += size) {
    results.push(...await Promise.all(items.slice(index, index + size).map(worker)))
  }
  return results
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' })
  if (!databaseConfigured()) {
    return res.status(503).json({ success: false, error: 'Database belum terhubung.' })
  }

  try {
    const listed = await resend('/emails/receiving?limit=100')
    if (!listed.ok) return res.status(listed.status).json({ success: false, error: listed.error })
    const messages = listed.data?.data || listed.data || []
    const results = await batches(messages, 5, async summary => {
      const detail = await resend(`/emails/receiving/${summary.id}`)
      const message = detail.ok ? { ...summary, ...detail.data } : summary
      await archiveMessage(message, 'inbound')
      return summary.id
    })
    return res.status(200).json({ success: true, archived: results.length })
  } catch (error) {
    console.error('Mail sync error:', error)
    return res.status(500).json({ success: false, error: 'Gagal menyinkronkan arsip email.' })
  }
}
