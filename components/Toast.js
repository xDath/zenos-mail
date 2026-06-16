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
