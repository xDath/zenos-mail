import { Resend } from 'resend'

export const config = { api: { bodyParser: false } }

async function rawBody(req) {
  const chunks = []
  let size = 0
  for await (const chunk of req) {
    size += chunk.length
    if (size > 1024 * 1024) throw new Error('Webhook payload too large')
    chunks.push(chunk)
  }
  return Buffer.concat(chunks)
}

function verifyWebhook(req, raw) {
  const secret = process.env.RESEND_WEBHOOK_SECRET?.trim()
  if (!secret) return null
  try {
    const client = new Resend(process.env.RESEND_API_KEY || 're_webhook_only')
    return client.webhooks.verify({
      payload: raw.toString('utf8'),
      webhookSecret: secret,
      headers: {
        id: req.headers['svix-id'],
        timestamp: req.headers['svix-timestamp'],
        signature: req.headers['svix-signature'],
      },
    })
  } catch { return null }
}

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
      body: JSON.stringify({ chat_id: chatId, text }),
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
    const raw = await rawBody(req)
    const event = verifyWebhook(req, raw)
    if (!event) return res.status(401).json({ ok: false, error: 'Invalid webhook signature' })
    const type = event?.type || 'unknown event'

    // Skip non-email events (domain.created, domain.updated, etc.)
    if (type !== 'email.received') {
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
    return res.status(500).json({ ok: false, error: 'Webhook processing failed' })
  }
}
