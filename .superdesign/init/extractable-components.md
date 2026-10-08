# Extractable Components

## DashboardLayout

- Source: `components/Layout.js`
- Category: layout
- Description: Web dashboard shell with brand bar, account state, four-section navigation, content slot, and toast layer.
- Extractable props: `activeItem` (string, default `receive`), `showConnection` (boolean, default `true`), `showToast` (boolean, default `false`)
- Hardcoded: ZENOS MAIL wordmark, Send/History/Inbox/Settings labels, logout label, visual styling
- Native note: the planned Flutter application needs a mobile bottom navigation shell rather than reusing this desktop web shell directly.

## Toast

- Source: `components/Toast.js`
- Category: basic
- Description: Compact transient success or error message.
- Extractable props: `isError` (boolean, default `false`), `showToast` (boolean, default `true`)
- Hardcoded: status symbols and timing behavior
