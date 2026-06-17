// POST /api/webhook/resend
// Receives Resend webhook events, forwards notification via Telegram only
// Only forwards email.received — skips domain.* and other noise
// NOTE: NO email-to-self forwarding (caused infinite loop: notify → CF → Resend → webhook → ...)

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

// Removed sendNotifyEmail — caused infinite forward loop (notify → CF forward → Resend → webhook → notify → ...)
// Telegram notification is sufficient; no email-to-self forwarding.

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' })
  }

  try {
    const event = req.body
    const type = event?.type || 'unknown event'

    // Skip non-email events (domain.created, domain.updated, etc.)
    if (type !== 'email.received' && !type.startsWith('email.')) {
      return res.status(200).json({ ok: true, skipped: true, reason: `event type '${type}' not forwarded` })
    }

    const from = event?.data?.from || event?.from || 'unknown'
    const subject = event?.data?.subject || event?.subject || '(no subject)'
    const to = event?.data?.to || event?.to || []
    const toStr = Array.isArray(to) ? to.join(', ') : to

    const telegramMsg = `📨 ${type}\n\nFrom: ${from}\nTo: ${toStr}\nSubject: ${subject}`

    await sendTelegram(telegramMsg)

    return res.status(200).json({ ok: true })
  } catch (err) {
    console.error('Webhook error:', err)
    return res.status(500).json({ ok: false, error: err.message })
  }
}
