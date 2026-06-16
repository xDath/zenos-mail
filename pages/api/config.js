// GET /api/config — return sender config (used by dashboard)
export default function handler(req, res) {
  return res.status(200).json({
    senderEmail: process.env.SENDER_EMAIL || 'onboarding@resend.dev',
    senderName: process.env.SENDER_NAME || 'Zenos Mail',
    replyTo: process.env.REPLY_TO || '',
    notifyEmail: process.env.NOTIFY_EMAIL || '',
    apiKeySet: !!(process.env.RESEND_API_KEY && !process.env.RESEND_API_KEY.startsWith('re_YOUR')),
  })
}
