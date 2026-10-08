import {
  databaseConfigured,
  registerPushDevice,
  unregisterPushDevice,
} from '../../lib/mail-store.js'

const TOKEN_PATTERN = /^[A-Za-z0-9_:\-]{80,4096}$/

export default async function handler(req, res) {
  if (!databaseConfigured()) {
    return res.status(503).json({ success: false, error: 'Database belum dikonfigurasi.' })
  }

  const token = typeof req.body?.token === 'string' ? req.body.token.trim() : ''
  if (!TOKEN_PATTERN.test(token)) {
    return res.status(400).json({ success: false, error: 'Token perangkat tidak valid.' })
  }

  try {
    if (req.method === 'POST') {
      await registerPushDevice(token, 'android')
      return res.status(200).json({ success: true })
    }
    if (req.method === 'DELETE') {
      await unregisterPushDevice(token)
      return res.status(200).json({ success: true })
    }
    return res.status(405).json({ success: false, error: 'Method not allowed' })
  } catch (error) {
    console.error('Device registration error:', error)
    return res.status(500).json({ success: false, error: 'Gagal menyimpan perangkat.' })
  }
}
