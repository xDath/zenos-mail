// GET /api/config — return sender config (used by dashboard)
export default function handler(req, res) {
  return res.status(200).json({
    success: true,
    data: {
      sender_email: process.env.SENDER_EMAIL || 'onboarding@resend.dev',
      sender_name: process.env.SENDER_NAME || 'Zenos Mail',
      reply_to: process.env.REPLY_TO || '',
      notify_email: process.env.NOTIFY_EMAIL || '',
      apiKeySet: !!(process.env.RESEND_API_KEY && !process.env.RESEND_API_KEY.startsWith('re_YOUR')),
    },
    senderEmail: process.env.SENDER_EMAIL || 'onboarding@resend.dev',
    senderName: process.env.SENDER_NAME || 'Zenos Mail',
    replyTo: process.env.REPLY_TO || '',
    notifyEmail: process.env.NOTIFY_EMAIL || '',
    apiKeySet: !!(process.env.RESEND_API_KEY && !process.env.RESEND_API_KEY.startsWith('re_YOUR')),
  })
}
