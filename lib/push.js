import { firebaseMessaging } from './firebase.js'
import { listPushDevices, removePushDevices } from './mail-store.js'

const INVALID_TOKEN_CODES = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
])

export async function sendAndroidPush(message) {
  const messaging = firebaseMessaging()
  if (!messaging) return { sent: 0, failed: 0, skipped: true }

  const tokens = await listPushDevices()
  if (!tokens.length) return { sent: 0, failed: 0, skipped: true }

  const subject = String(message.subject || '').trim() || 'Tanpa subjek'
  const recipient = Array.isArray(message.to) ? message.to[0] : message.to
  const result = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: 'Email baru',
      body: `${subject}${recipient ? `  ·  ${recipient}` : ''}`,
    },
    data: {
      type: 'email.received',
      email_id: String(message.id || message.email_id || ''),
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'zenos_mail_inbox',
        color: '#E8913C',
        defaultSound: true,
      },
    },
  })

  const invalidTokens = []
  result.responses.forEach((response, index) => {
    if (!response.success && INVALID_TOKEN_CODES.has(response.error?.code)) {
      invalidTokens.push(tokens[index])
    }
  })
  await removePushDevices(invalidTokens)

  return {
    sent: result.successCount,
    failed: result.failureCount,
    removed: invalidTokens.length,
  }
}
