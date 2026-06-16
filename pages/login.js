import { useState } from 'react'
import { useRouter } from 'next/router'
import Head from 'next/head'

export default function Login() {
  const router = useRouter()
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleLogin(e) {
    e.preventDefault()
    if (!password) return
    setLoading(true)
    setError('')
    try {
      const res = await fetch('/api/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password }),
      })
      const data = await res.json()
      if (data.success) {
        const redirect = router.query.redirect || '/'
        router.push(redirect)
      } else {
        setError(data.error || 'Invalid password')
      }
    } catch (err) {
      setError('Connection error')
    }
    setLoading(false)
  }

  return (
    <>
      <Head><title>ZENOS MAIL — Login</title></Head>
      <div className="login">
        <div className="login__card">
          <div className="login__brand">ZENOS MAIL</div>
          <div className="login__subtitle">ENTER PASSWORD</div>
          <form onSubmit={handleLogin}>
            <input
              className="login__input"
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="········"
              autoFocus
            />
            <button type="submit" className="btn btn--primary" style={{ width: '100%' }} disabled={loading}>
              {loading ? <span className="spinner" /> : 'LOGIN'}
            </button>
            {error && <div className="login__error">{error}</div>}
          </form>
        </div>
      </div>
    </>
  )
}
