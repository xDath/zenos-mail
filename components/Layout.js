import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import Toast from '../components/Toast'

const TABS = [
  { id: 'send', label: 'SEND' },
  { id: 'history', label: 'HISTORY' },
  { id: 'receive', label: 'INBOX' },
]

export default function DashboardLayout({ children }) {
  const router = useRouter()
  const [activeTab, setActiveTab] = useState('send')
  const [status, setStatus] = useState('checking')
  const [senderEmail, setSenderEmail] = useState('')
  const [toast, setToast] = useState(null)
  const [isElectron, setIsElectron] = useState(false)

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

  useEffect(() => {
    setIsElectron(typeof window !== 'undefined' && window.electronAPI)
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
        {TABS.map(tab => (
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
