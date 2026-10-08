import { useState, useEffect, useRef } from 'react'
import Layout from '../components/Layout'
import SettingsPanel from '../components/SettingsPanel'
import Head from 'next/head'
import { sendingReady } from '../lib/resend'

export default function Dashboard() {
  return (
    <>
      <Head><title>ZENOS MAIL</title></Head>
      <Layout tabs={[
        { id: 'send', label: 'SEND' },
        { id: 'history', label: 'HISTORY' },
        { id: 'receive', label: 'INBOX' },
        { id: 'settings', label: 'SETTINGS' },
      ]}>
        {({ activeTab, showToast }) => {
          switch (activeTab) {
            case 'send': return <SendPanel showToast={showToast} />
            case 'history': return <HistoryPanel showToast={showToast} />
            case 'receive': return <InboxPanel showToast={showToast} />
            case 'settings': return <SettingsPanel showToast={showToast} />
            default: return null
          }
        }}
      </Layout>
    </>
  )
}

/* ── SEND PANEL ──────────────────────────────────────────── */
function SendPanel({ showToast }) {
  const [domains, setDomains] = useState([])
  const [fromEmail, setFromEmail] = useState('')
  const [domainError, setDomainError] = useState('')
  const [to, setTo] = useState('')
  const [cc, setCc] = useState('')
  const [bcc, setBcc] = useState('')
  const [subject, setSubject] = useState('')
  const [body, setBody] = useState('')
  const [htmlMode, setHtmlMode] = useState(false)
  const [showCcBcc, setShowCcBcc] = useState(false)
  const [sending, setSending] = useState(false)
  const [attachments, setAttachments] = useState([])
  const fileRef = useRef(null)

  useEffect(() => {
    const saved = localStorage.getItem('zenos_sender_email')
    Promise.all([fetch('/api/config').then(r => r.json()), fetch('/api/domains').then(r => r.json())])
      .then(async ([config, result]) => {
        if (!result.success) throw new Error(result.error || 'Gagal memuat domain')
        const resolved = await Promise.all((result.data?.data || []).map(async domain => {
          if (domain.status !== 'partially_verified') return domain
          const detail = await fetch(`/api/domains/${domain.id}`).then(r => r.json())
          return detail.success ? detail.data : domain
        }))
        const verified = resolved.filter(sendingReady)
        setDomains(verified)
        const preferred = saved && verified.some(d => saved.toLowerCase().endsWith(`@${d.name.toLowerCase()}`)) ? saved : config.senderEmail
        setFromEmail(preferred || (verified[0] ? `hello@${verified[0].name}` : ''))
      })
      .catch(err => setDomainError(err.message))
  }, [])

  function handleFiles(e) {
    const files = Array.from(e.target.files || [])
    const readers = files.map(f => new Promise((resolve) => {
      const r = new FileReader()
      r.onload = () => resolve({ filename: f.name, content: r.result.split(',')[1], size: f.size })
      r.readAsDataURL(f)
    }))
    Promise.all(readers).then(newFiles => {
      setAttachments(prev => [...prev, ...newFiles])
    })
    e.target.value = ''
  }

  function removeAttachment(idx) {
    setAttachments(prev => prev.filter((_, i) => i !== idx))
  }

  function formatSize(bytes) {
    if (bytes < 1024) return bytes + ' B'
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
  }

  async function handleSend(e) {
    e.preventDefault()
    if (sending) return
    const toList = to.split(/[,;]\s*/).filter(Boolean)
    if (!toList.length) { showToast({ type: 'error', message: 'Recipient required' }); return }
    if (!subject.trim()) { showToast({ type: 'error', message: 'Subject required' }); return }
    if (!body.trim()) { showToast({ type: 'error', message: 'Body required' }); return }

    if (!domains.some(d => fromEmail.toLowerCase().endsWith(`@${d.name.toLowerCase()}`))) {
      showToast({ type: 'error', message: 'Pilih domain pengirim yang sudah terverifikasi.' }); return
    }
    const identity = JSON.parse(localStorage.getItem('zenos_sender_identity') || '{}')

    setSending(true)
    try {
      const payload = { to: toList, subject: subject.trim() }
      if (htmlMode) payload.html = body
      else payload.text = body
      const ccList = cc.split(/[,;]\s*/).filter(Boolean)
      if (ccList.length) payload.cc = ccList
      const bccList = bcc.split(/[,;]\s*/).filter(Boolean)
      if (bccList.length) payload.bcc = bccList
      if (attachments.length) payload.attachments = attachments.map(a => ({ filename: a.filename, content: a.content }))
      payload.sender_email = fromEmail.trim()
      if (identity.senderName) payload.sender_name = identity.senderName
      if (identity.replyTo) payload.reply_to = identity.replyTo

      const res = await fetch('/api/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })
      const data = await res.json()
      if (data.success) {
        localStorage.setItem('zenos_sender_email', fromEmail.trim())
        showToast({ type: 'success', message: `Sent — ID: ${data.id}` })
        const h = JSON.parse(localStorage.getItem('zenos_history') || '[]')
        h.unshift({ id: data.id, from: fromEmail.trim(), to: toList.join(', '), cc: ccList.join(', '), bcc: bccList.join(', '), subject: payload.subject, body, htmlMode, attachments: attachments.map(a => a.filename), time: new Date().toISOString() })
        if (h.length > 100) h.length = 100
        localStorage.setItem('zenos_history', JSON.stringify(h))
        setTo(''); setCc(''); setBcc(''); setSubject(''); setBody(''); setAttachments([])
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
        <div className="section-intro"><span className="eyebrow">COMPOSE / 01</span><h1>Tulis email.</h1><p>Pilih domain pengirim, lalu kirim dari alamat yang kamu butuhkan.</p></div>
        {domainError && <p className="inline-error">{domainError}</p>}
        <div className="form__row">
          <div className="form__group"><label className="form__label" htmlFor="sender-local">From · alamat</label><input id="sender-local" className="form__input" value={fromEmail.split('@')[0] || ''} onChange={e => setFromEmail(`${e.target.value}@${fromEmail.split('@')[1] || domains[0]?.name || ''}`)} placeholder="hello" required /></div>
          <div className="form__group"><label className="form__label" htmlFor="sender-domain">Domain</label><select id="sender-domain" className="form__input" value={fromEmail.split('@')[1] || ''} onChange={e => setFromEmail(`${fromEmail.split('@')[0] || 'hello'}@${e.target.value}`)} required><option value="">Pilih domain</option>{domains.map(d => <option key={d.id} value={d.name}>@{d.name}</option>)}</select></div>
        </div>
        <div className="form__group">
          <label className="form__label">To</label>
            <input className="form__input" value={to} onChange={e => setTo(e.target.value)} placeholder="email@example.com" required />
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

        {attachments.length > 0 && (
          <div style={{ marginBottom: 12 }}>
            {attachments.map((a, i) => (
              <span key={i} style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '4px 10px', background: 'var(--text)', color: 'var(--white)', fontFamily: 'var(--font-mono)', fontSize: 11, letterSpacing: '0.05em', marginRight: 6, marginBottom: 6 }}>
                {a.filename} <span style={{ color: 'var(--muted)' }}>{formatSize(a.size)}</span>
                <button type="button" onClick={() => removeAttachment(i)} style={{ background: 'none', border: 'none', color: '#E53935', cursor: 'pointer', fontSize: 14, padding: '0 2px' }}>✕</button>
              </span>
            ))}
          </div>
        )}

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
          <button type="button" className="btn btn--ghost" onClick={() => fileRef.current?.click()}>
            📎 ATTACH
          </button>
          <input ref={fileRef} type="file" multiple onChange={handleFiles} style={{ display: 'none' }} />
          <button type="button" className="btn btn--ghost" onClick={() => { setTo(''); setCc(''); setBcc(''); setSubject(''); setBody(''); setAttachments([]) }}>
            CLEAR
          </button>
        </div>
      </form>
    </div>
  )
}

/* ── HISTORY PANEL ───────────────────────────────────────── */
function HistoryPanel() {
  const [view, setView] = useState('list')
  const [detail, setDetail] = useState(null)
  const [history, setHistory] = useState([])
  useEffect(() => {
    try { setHistory(JSON.parse(localStorage.getItem('zenos_history') || '[]')) } catch { setHistory([]) }
  }, [])

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
              {detail.from && <div className="detail__field"><span>From:</span> {detail.from}</div>}
              {detail.cc && <div className="detail__field"><span>CC:</span> {detail.cc}</div>}
              {detail.bcc && <div className="detail__field"><span>BCC:</span> {detail.bcc}</div>}
              {detail.attachments?.length > 0 && <div className="detail__field"><span>Attachments:</span> {detail.attachments.join(', ')}</div>}
              <div className="detail__field"><span>Date:</span> {formatTime(detail.time)}</div>
              <div className="detail__field"><span>ID:</span> {detail.id}</div>
            </div>
          </div>
          {detail.body && (
            <div className="detail__body">
              {detail.htmlMode
                ? <iframe className="email-frame" title="Sent email content" sandbox="" referrerPolicy="no-referrer" srcDoc={detail.body} />
                : <pre style={{ fontFamily: 'var(--font-mono)', fontSize: 13, lineHeight: 1.6, whiteSpace: 'pre-wrap', color: 'var(--text)' }}>{detail.body}</pre>
              }
            </div>
          )}
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
            <button type="button" key={idx} className="item" onClick={() => { setDetail(entry); setView('detail') }}>
              <span className="item__index">{String(idx + 1).padStart(3, '0')}</span>
              <div className="item__content">
                <div className="item__subject">{entry.subject}</div>
                <div className="item__meta">
                  <span>→ {entry.to}</span>
                  <span>{formatTime(entry.time)}</span>
                </div>
              </div>
              <span className="item__arrow">→</span>
            </button>
          ))
        )}
      </div>
    </div>
  )
}

/* ── INBOX PANEL (auto-poll 60s) ─────────────────────────── */
function InboxPanel({ showToast }) {
  const [emails, setEmails] = useState([])
  const [view, setView] = useState('list')
  const [detail, setDetail] = useState(null)
  const [loading, setLoading] = useState(false)
  const [loaded, setLoaded] = useState(false)
  const [filter, setFilter] = useState('all')

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

  // Auto-load on mount + poll every 60s
  useEffect(() => {
    loadInbox(true)
    const interval = setInterval(() => loadInbox(true), 60000)
    return () => clearInterval(interval)
  }, [])

  function formatTime(iso) {
    return new Date(iso).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
  }

  if (view === 'detail' && detail) {
    return <InboxDetailView detail={detail} onBack={() => setView('list')} />
  }

  const recipientDomains = [...new Set(emails.flatMap(email => (Array.isArray(email.to) ? email.to : [email.to]).filter(Boolean).map(address => address.split('@')[1]?.toLowerCase())).filter(Boolean))]
  const visibleEmails = filter === 'all' ? emails : emails.filter(email => (Array.isArray(email.to) ? email.to : [email.to]).some(address => address?.toLowerCase().endsWith(`@${filter}`)))

  return (
    <div className="panel active">
      {!loaded ? (
        <div style={{ maxWidth: 780, margin: '60px auto', textAlign: 'center' }}>
          <p style={{ color: 'var(--muted)', fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em' }}>LOADING…</p>
        </div>
      ) : (
        <div className="list">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <div className="list__count">{visibleEmails.length} RECEIVED</div>
            <button className="btn btn--small btn--ghost" onClick={() => loadInbox()} disabled={loading}>
              {loading ? '...' : 'REFRESH'}
            </button>
          </div>
          <div className="filter-bar"><label className="form__label" htmlFor="inbox-domain">DOMAIN</label><select id="inbox-domain" className="form__input" value={filter} onChange={e => setFilter(e.target.value)}><option value="all">Semua domain</option>{recipientDomains.map(domain => <option key={domain} value={domain}>@{domain}</option>)}</select></div>
          {!visibleEmails.length ? (
            <div className="list__empty">NO EMAILS YET</div>
          ) : (
            visibleEmails.map((email, idx) => (
              <button type="button" key={email.id || idx} className="item" onClick={() => { setDetail(email); setView('detail') }}>
                <span className="item__index">{String(idx + 1).padStart(3, '0')}</span>
                <div className="item__content">
                  <div className="item__subject">{email.subject || '(no subject)'}</div>
                  <div className="item__meta">
                    <span>← {email.from || '—'}</span>
                    <span>→ {Array.isArray(email.to) ? email.to.join(', ') : email.to || '—'}</span>
                    <span>{email.created_at ? formatTime(email.created_at) : '—'}</span>
                  </div>
                </div>
                <span className="item__arrow">→</span>
              </button>
            ))
          )}
        </div>
      )}
    </div>
  )
}

/* ── INBOX DETAIL (fetches full email body) ───────────────── */
function InboxDetailView({ detail, onBack }) {
  const [full, setFull] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (detail?.id) {
      fetch(`/api/inbox/${detail.id}`)
        .then(r => r.json())
        .then(d => {
          if (d.success) setFull(d.data)
        })
        .catch(() => {})
        .finally(() => setLoading(false))
    }
  }, [detail?.id])

  function formatTime(iso) {
    return new Date(iso).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
  }

  const email = full || detail

  return (
    <div className="panel active">
      <div className="detail">
        <button className="detail__back" onClick={onBack}>← BACK TO LIST</button>
        <div className="detail__header">
          <h1 className="detail__subject">{email.subject || '(no subject)'}</h1>
          <div className="detail__fields">
            <div className="detail__field"><span>From:</span> {email.from || '—'}</div>
            <div className="detail__field"><span>To:</span> {Array.isArray(email.to) ? email.to.join(', ') : (email.to || '—')}</div>
            <div className="detail__field"><span>Date:</span> {email.created_at ? formatTime(email.created_at) : '—'}</div>
          </div>
        </div>
        <div className="detail__body">
          {loading
            ? <span style={{ color: 'var(--muted)', fontFamily: 'var(--font-mono)', fontSize: 11 }}>LOADING…</span>
            : email.html ? <iframe className="email-frame" title="Received email content" sandbox="" referrerPolicy="no-referrer" srcDoc={email.html} /> : <pre className="email-text">{email.text || email.body || '(no content)'}</pre>
          }
        </div>
      </div>
    </div>
  )
}
