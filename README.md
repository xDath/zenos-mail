# Zenos Mail

Web dashboard + API untuk email @zenos.studio via Resend.

## Deploy

```bash
npm install
npm run dev    # dev at :3077
npm run build  # production build
```

## Env Variables (set di Vercel)

| Variable | Description |
|---|---|
| `RESEND_API_KEY` | API key from resend.com/api-keys |
| `SENDER_EMAIL` | From address |
| `SENDER_NAME` | From name |
| `REPLY_TO` | Reply-to address |
| `NOTIFY_EMAIL` | Notification destination |
| `DASHBOARD_PASSWORD` | Password for login gate |
| `TELEGRAM_BOT_TOKEN` | (optional) Bot token for Telegram notif |
| `TELEGRAM_CHAT_ID` | (optional) Chat ID for Telegram notif |

## API Routes

- `POST /api/send` — kirim email via Resend
- `GET /api/inbox` — list received emails
- `POST /api/webhook/resend` — webhook endpoint (pasang di Resend dashboard)
- `POST /api/login` — dashboard login
