# Route Map

Framework: Next.js 16 Pages Router with `proxy.js` protecting authenticated pages and APIs.

| URL | File | Layout | Summary |
| --- | --- | --- | --- |
| `/login` | `pages/login.js` | standalone | Password sign-in card. |
| `/` | `pages/index.js` | `components/Layout.js` | Tabbed Send, History, Inbox, and Settings workspace. |
| `/api/login` | `pages/api/login.js` | API | Creates signed session cookie. |
| `/api/logout` | `pages/api/logout.js` | API | Clears session cookie. |
| `/api/config` | `pages/api/config.js` | API | Returns non-secret sender defaults and setup state. |
| `/api/send` | `pages/api/send.js` | API | Validates and sends an email through Resend. |
| `/api/inbox` | `pages/api/inbox.js` | API | Lists received emails. |
| `/api/inbox/[id]` | `pages/api/inbox/[id].js` | API | Retrieves full received email content. |
| `/api/domains` | `pages/api/domains/index.js` | API | Lists or creates domains. |
| `/api/domains/[id]` | `pages/api/domains/[id].js` | API | Domain detail, verification, and receiving status. |
| `/api/notifications` | `pages/api/notifications.js` | API | Reads push setup and sends a test notification. |
| `/api/webhook/resend` | `pages/api/webhook/resend.js` | public API | Verifies Resend webhooks and emits inbound notifications. |

`proxy.js` permits `/login`, login/logout, the Resend webhook, and favicon publicly. All other routes require a valid `zenos_session` cookie.
