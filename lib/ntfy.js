const TOPIC_PATTERN = /^[a-zA-Z0-9_-]{32,64}$/

export function notificationTopic() {
  const topic = process.env.NTFY_TOPIC?.trim() || ''
  return TOPIC_PATTERN.test(topic) ? topic : ''
}

export async function sendNtfy() {
  const topic = notificationTopic()
  if (!topic) return false

  const response = await fetch('https://ntfy.sh/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      topic,
      title: 'Zenos Mail',
      message: 'Ada email baru. Buka inbox untuk membacanya.',
      priority: 4,
      tags: ['email'],
      click: 'https://zenos-mail.vercel.app/?tab=receive',
    }),
    signal: AbortSignal.timeout(8000),
  })

  if (!response.ok) throw new Error(`ntfy returned HTTP ${response.status}`)
  return true
}
