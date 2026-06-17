import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import Toast from '../components/Toast'

export default function DashboardLayout({ children, tabs }) {
  const router = useRouter()
  const defaultTabs = tabs || [
    { id: 'send', label: 'SEND' },
    { id: 'history', label: 'HISTORY' },
    { id: 'receive', label: 'INBOX' },
    { id: 'settings', label: 'SETTINGS' },
  ]
  const [activeTab, setActiveTab] = useState('send')
  const [status, setStatus] = useState('checking')
  const [senderEmail, setSenderEmail] = useState('')
  const [toast, setToast] = useState(null)

  useEffect(() => {
    fetch('/api/config')
      .then(r => r.json())
      .then(data => {
        if (data.apiKeySet) {
          setStatus('active')
          setSenderEmail(data.senderEmail)
        } else {
          setStatus('error')
        }
      })
      .catch(() => setStatus('error'))
  }, [])

  const handleLogout = async () => {
    await fetch('/api/logout', { method: 'POST' })
    router.push('/login')
  }

  return (
    <div className="app">
      <header className="header">
        <div className="header__brand">ZENOS MAIL</div>
        <div className="header__right">
          <div className="header__status">
            <span className={`header__dot ${status}`}></span>
            {senderEmail || '...'}
          </div>
          <button className="header__logout" onClick={handleLogout}>LOGOUT</button>
        </div>
      </header>

      <nav className="nav">
        {defaultTabs.map(tab => (
          <button
            key={tab.id}
            className={`nav__tab${activeTab === tab.id ? ' active' : ''}`}
            onClick={() => setActiveTab(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </nav>

      <main style={{ flex: 1 }}>
        {children({ activeTab, setActiveTab, showToast: setToast })}
      </main>

      {toast && <Toast type={toast.type} message={toast.message} onDone={() => setToast(null)} />}
    </div>
  )
}
