// POST /api/webhook/resend
// Receives Resend webhook events, forwards notification via email + Telegram

async function sendTelegram(text) {
  const token = process.env.TELEGRAM_BOT_TOKEN
  const chatId = process.env.TELEGRAM_CHAT_ID
  if (!token || !chatId) return
  try {
    await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chat_id: chatId, text, parse_mode: 'HTML' }),
    })
  } catch {}
}

async function sendNotifyEmail(subject, body) {
  const apiKey = process.env.RESEND_API_KEY
  const notifyEmail = process.env.NOTIFY_EMAIL
  const senderEmail = process.env.SENDER_EMAIL || 'onboarding@resend.dev'
  const senderName = process.env.SENDER_NAME || 'Zenos Mail'
  if (!notifyEmail || !apiKey) return
  try {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: `${senderName} <${senderEmail}>`,
        to: [notifyEmail],
        subject,
        text: body,
      }),
    })
  } catch {}
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    const event = req.body
    const from = event?.data?.from || event?.from || 'unknown'
    const subject = event?.data?.subject || event?.subject || '(no subject)'
    const to = event?.data?.to || event?.to || []
    const toStr = Array.isArray(to) ? to.join(', ') : to
    const type = event?.type || 'unknown event'

    const telegramMsg = `📨 ${type}\n\nFrom: ${from}\nTo: ${toStr}\nSubject: ${subject}`
    const notifySubject = `📨 ${subject} — from ${from}`

    await Promise.all([
      sendTelegram(telegramMsg),
      sendNotifyEmail(notifySubject, `New email received:\n\nFrom: ${from}\nTo: ${toStr}\nSubject: ${subject}\n\n— Zenos Mail`),
    ])

    return res.status(200).json({ ok: true })
  } catch (err) {
    console.error('Webhook error:', err)
    return res.status(500).json({ ok: false, error: err.message })
  }
}
