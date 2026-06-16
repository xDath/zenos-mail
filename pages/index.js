import { useState } from 'react'
import Layout from '../components/Layout'
import Head from 'next/head'

export default function Dashboard() {
  return (
    <>
      <Head><title>ZENOS MAIL</title></Head>
      <Layout>
        {({ activeTab, showToast }) => {
          switch (activeTab) {
            case 'send': return <SendPanel showToast={showToast} />
            case 'history': return <HistoryPanel showToast={showToast} />
            case 'receive': return <InboxPanel showToast={showToast} />
            default: return null
          }
        }}
      </Layout>
    </>
  )
}

function SendPanel({ showToast }) {
  const [to, setTo] = useState('')
  const [cc, setCc] = useState('')
  const [bcc, setBcc] = useState('')
  const [subject, setSubject] = useState('')
  const [body, setBody] = useState('')
  const [htmlMode, setHtmlMode] = useState(false)
  const [showCcBcc, setShowCcBcc] = useState(false)
  const [sending, setSending] = useState(false)

  async function handleSend(e) {
    e.preventDefault()
    if (sending) return
    const toList = to.split(/[,;]\s*/).filter(Boolean)
    if (!toList.length) { showToast({ type: 'error', message: 'Recipient required' }); return }
    if (!subject.trim()) { showToast({ type: 'error', message: 'Subject required' }); return }
    if (!body.trim()) { showToast({ type: 'error', message: 'Body required' }); return }

    setSending(true)
    try {
      const payload = { to: toList, subject: subject.trim() }
      if (htmlMode) payload.html = body
      else payload.text = body
      const ccList = cc.split(/[,;]\s*/).filter(Boolean)
      if (ccList.length) payload.cc = ccList
      const bccList = bcc.split(/[,;]\s*/).filter(Boolean)
      if (bccList.length) payload.bcc = bccList

      const res = await fetch('/api/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })
      const data = await res.json()
      if (data.success) {
        showToast({ type: 'success', message: `Sent — ID: ${data.id}` })
        // save to history
        const h = JSON.parse(localStorage.getItem('zenos_history') || '[]')
        h.unshift({ id: data.id, to: toList.join(', '), cc: ccList.join(', '), subject: payload.subject, htmlMode, time: new Date().toISOString() })
        if (h.length > 100) h.length = 100
        localStorage.setItem('zenos_history', JSON.stringify(h))
        setTo(''); setCc(''); setBcc(''); setSubject(''); setBody('')
      } else {
        showToast({ type: 'error', message: data.error || 'Send failed' })
      }
    } catch (err) {
      showToast({ type: 'error', message: err.message || 'Network error' })
    }
    setSending(false)
  }

  return (
    <div className="panel active">
      <form className="form" onSubmit={handleSend}>
        <div className="form__group">
          <label className="form__label">To</label>
          <input className="form__input" value={to} onChange={e => setTo(e.target.value)} placeholder="email@example.com" />
        </div>

        <div style={{ display: showCcBcc ? 'block' : 'none' }}>
          <div className="form__group">
            <label className="form__label">CC</label>
            <input className="form__input" value={cc} onChange={e => setCc(e.target.value)} placeholder="cc@example.com" />
          </div>
          <div className="form__group">
            <label className="form__label">BCC</label>
            <input className="form__input" value={bcc} onChange={e => setBcc(e.target.value)} placeholder="bcc@example.com" />
          </div>
        </div>

        <div className="form__group">
          <label className="form__label">Subject</label>
          <input className="form__input" value={subject} onChange={e => setSubject(e.target.value)} placeholder="Your subject..." />
        </div>

        <div className="form__group">
          <label className="form__label">{htmlMode ? 'HTML' : 'Plain Text'}</label>
          <textarea
            className="form__textarea"
            value={body}
            onChange={e => setBody(e.target.value)}
            placeholder={htmlMode ? '<p>Write HTML…</p>' : 'Write your message…'}
          />
        </div>

        <div className="form__actions">
          <button type="submit" className="btn btn--primary" disabled={sending}>
            {sending ? <span className="spinner" /> : 'SEND EMAIL'}
          </button>
          <button type="button" className={`btn btn--ghost${showCcBcc ? ' active' : ''}`} onClick={() => setShowCcBcc(!showCcBcc)}>
            {showCcBcc ? '− CC/BCC' : '+ CC/BCC'}
          </button>
          <button type="button" className={`btn btn--ghost${htmlMode ? ' active' : ''}`} onClick={() => setHtmlMode(!htmlMode)}>
            {htmlMode ? 'HTML' : 'TEXT'}
          </button>
          <button type="button" className="btn btn--ghost" onClick={() => { setTo(''); setCc(''); setBcc(''); setSubject(''); setBody('') }}>
            CLEAR
          </button>
        </div>
      </form>
    </div>
  )
}

function HistoryPanel() {
  const [view, setView] = useState('list')
  const [detail, setDetail] = useState(null)
  const history = JSON.parse(typeof window !== 'undefined' ? localStorage.getItem('zenos_history') || '[]' : '[]')

  function formatTime(iso) {
    return new Date(iso).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
  }

  if (view === 'detail' && detail) {
    return (
      <div className="panel active">
        <div className="detail">
          <button className="detail__back" onClick={() => setView('list')}>← BACK TO LIST</button>
          <div className="detail__header">
            <h1 className="detail__subject">{detail.subject}</h1>
            <div className="detail__fields">
              <div className="detail__field"><span>To:</span> {detail.to}</div>
              {detail.cc && <div className="detail__field"><span>CC:</span> {detail.cc}</div>}
              <div className="detail__field"><span>Date:</span> {formatTime(detail.time)}</div>
              <div className="detail__field"><span>ID:</span> {detail.id}</div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="panel active">
      <div className="list">
        <div className="list__count">{history.length} SENT</div>
        {!history.length ? (
          <div className="list__empty">NO EMAILS SENT YET</div>
        ) : (
          history.map((entry, idx) => (
            <div key={idx} className="item" onClick={() => { setDetail(entry); setView('detail') }}>
              <span className="item__index">{String(idx + 1).padStart(3, '0')}</span>
              <div className="item__content">
                <div className="item__subject">{entry.subject}</div>
                <div className="item__meta">
                  <span>→ {entry.to}</span>
                  <span>{formatTime(entry.time)}</span>
                </div>
              </div>
              <span className="item__arrow">→</span>
            </div>
          ))
        )}
      </div>
    </div>
  )
}

function InboxPanel({ showToast }) {
  const [emails, setEmails] = useState([])
  const [view, setView] = useState('list')
  const [detail, setDetail] = useState(null)
  const [loading, setLoading] = useState(false)
  const [loaded, setLoaded] = useState(false)

  async function loadInbox(silent = false) {
    setLoading(true)
    try {
      const res = await fetch('/api/inbox')
      const data = await res.json()
      if (data.success) {
        const list = data.data?.data || data.data || []
        setEmails(list)
        if (!silent) showToast({ type: 'success', message: `${list.length} email(s) loaded` })
      } else {
        if (!silent) showToast({ type: 'error', message: data.error || 'Failed to load' })
      }
    } catch (err) {
      if (!silent) showToast({ type: 'error', message: err.message })
    }
    setLoading(false)
    setLoaded(true)
  }

  function formatTime(iso) {
    return new Date(iso).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
  }

  if (view === 'detail' && detail) {
    return (
      <div className="panel active">
        <div className="detail">
          <button className="detail__back" onClick={() => setView('list')}>← BACK TO LIST</button>
          <div className="detail__header">
            <h1 className="detail__subject">{detail.subject || '(no subject)'}</h1>
            <div className="detail__fields">
              <div className="detail__field"><span>From:</span> {detail.from || '—'}</div>
              <div className="detail__field"><span>To:</span> {Array.isArray(detail.to) ? detail.to.join(', ') : (detail.to || '—')}</div>
              <div className="detail__field"><span>Date:</span> {detail.created_at ? formatTime(detail.created_at) : '—'}</div>
            </div>
          </div>
          <div className="detail__body" dangerouslySetInnerHTML={{ __html: detail.html || detail.text || detail.body || '(no content)' }} />
        </div>
      </div>
    )
  }

  return (
    <div className="panel active">
      {!loaded ? (
        <div style={{ maxWidth: 780, margin: '60px auto', textAlign: 'center' }}>
          <button className="btn btn--primary" onClick={() => loadInbox()}>
            {loading ? <span className="spinner" /> : 'LOAD INBOX'}
          </button>
        </div>
      ) : (
        <div className="list">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <div className="list__count">{emails.length} RECEIVED</div>
            <button className="btn btn--small btn--ghost" onClick={() => loadInbox()} disabled={loading}>
              {loading ? '...' : 'REFRESH'}
            </button>
          </div>
          {!emails.length ? (
            <div className="list__empty">NO EMAILS YET</div>
          ) : (
            emails.map((email, idx) => (
              <div key={email.id || idx} className="item" onClick={() => { setDetail(email); setView('detail') }}>
                <span className="item__index">{String(idx + 1).padStart(3, '0')}</span>
                <div className="item__content">
                  <div className="item__subject">{email.subject || '(no subject)'}</div>
                  <div className="item__meta">
                    <span>← {email.from || '—'}</span>
                    <span>{email.created_at ? formatTime(email.created_at) : '—'}</span>
                  </div>
                </div>
                <span className="item__arrow">→</span>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  )
}
