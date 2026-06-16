// POST /api/webhook/resend
// Receives Resend webhook events, forwards notification via email + Telegram

const RESEND_API_KEY = process.env.RESEND_API_KEY
const SENDER_EMAIL = process.env.SENDER_EMAIL || 'onboarding@resend.dev'
const SENDER_NAME = process.env.SENDER_NAME || 'Zenos Mail'
const NOTIFY_EMAIL = process.env.NOTIFY_EMAIL

function sendTelegram(text) {
  const token = process.env.TELEGRAM_BOT_TOKEN
  const chatId = process.env.TELEGRAM_CHAT_ID
  if (!token || !chatId) return Promise.resolve()
  return fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, text, parse_mode: 'HTML' }),
  }).catch(() => {})
}

async function sendNotifyEmail(subject, body) {
  if (!NOTIFY_EMAIL || !RESEND_API_KEY) return
  try {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: `${SENDER_NAME} <${SENDER_EMAIL}>`,
        to: [NOTIFY_EMAIL],
        subject,
        text: body,
      }),
    })
  } catch {}
}

export async function POST(req) {
  try {
    const body = await req.json()
    const event = body

    // Extract email details
    const from = event?.data?.from || event?.from || 'unknown'
    const subject = event?.data?.subject || event?.subject || '(no subject)'
    const to = event?.data?.to || event?.to || []
    const toStr = Array.isArray(to) ? to.join(', ') : to
    const type = event?.type || 'unknown event'

    // Build notification text
    const email = `📨 New email received at ${new Date().toLocaleString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false })}
    
From: ${from}
To: ${toStr}
Subject: ${subject}
Type: ${type}`

    const notifySubject = `📨 ${subject} — from ${from}`

    // Send notifications in parallel
    await Promise.all([
      sendTelegram(email),
      sendNotifyEmail(notifySubject, `New email received:\n\nFrom: ${from}\nTo: ${toStr}\nSubject: ${subject}\n\n— Zenos Mail`),
    ])

    return Response.json({ ok: true })
  } catch (err) {
    console.error('Webhook error:', err)
    return Response.json({ ok: false, error: err.message }, { status: 500 })
  }
}
