# Page Dependency Trees

## `/` — Mail Workspace

Entry: `pages/index.js`

Dependencies:

- `components/Layout.js`
  - `components/Toast.js`
- `components/SettingsPanel.js`
- `lib/resend.js`
- `styles/global.css` via `pages/_app.js`
- `pages/_document.js` for Inter and JetBrains Mono

Rendered states inside `pages/index.js`:

- Send panel: sender local part, domain selection, To/CC/BCC, subject, plain text or HTML body, attachments, send and clear actions.
- History panel: locally stored sent-message list and message detail.
- Inbox panel: received-message list, domain filter, refresh, and full message detail.
- Settings panel: domains and DNS records, sender identity, and Android notification setup.

## `/login` — Sign In

Entry: `pages/login.js`

Dependencies:

- `styles/global.css` via `pages/_app.js`
- `pages/_document.js` for Inter and JetBrains Mono

Rendered state: centered password card with product wordmark, password input, primary login button, loading spinner, and inline error.
