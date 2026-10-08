# Shared UI Components

Framework: React 19 with Next.js Pages Router. Components use custom CSS classes from `styles/global.css`; there is no third-party component library.

## Toast

- Path: `components/Toast.js`
- Description: Timed success or error notification shown by the dashboard shell.
- Props: `type`, `message`, `onDone`

```jsx
import { useEffect } from 'react'

export default function Toast({ type, message, onDone }) {
  useEffect(() => {
    const t = setTimeout(onDone, 4000)
    return () => clearTimeout(t)
  }, [])

  return (
    <div className={`toast visible toast--${type || 'success'}`}>
      <span>{type === 'success' ? '✓' : '✗'}</span>
      <span>{message}</span>
    </div>
  )
}
```

The remaining UI is page-specific: compose, sent history, inbox, message detail, domain management, sender identity, and Android push settings.
