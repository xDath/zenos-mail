import { notificationTopic, sendNtfy } from '../../lib/ntfy.js'

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store')
  const topic = notificationTopic()

  if (req.method === 'GET') {
    return res.status(200).json({ success: true, configured: !!topic, topic })
  }

  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' })
  if (!topic) return res.status(503).json({ success: false, error: 'Notifikasi Android belum dikonfigurasi.' })

  const origin = req.headers.origin
  const host = req.headers['x-forwarded-host'] || req.headers.host
  let sameOrigin = false
  try { sameOrigin = !!origin && !!host && new URL(origin).host === host } catch {}
  if (!sameOrigin) {
    return res.status(403).json({ success: false, error: 'Permintaan ditolak.' })
  }

  try {
    await sendNtfy()
    return res.status(200).json({ success: true })
  } catch (error) {
    console.error('Notification test failed:', error)
    return res.status(502).json({ success: false, error: 'Gagal mengirim tes notifikasi.' })
  }
}
