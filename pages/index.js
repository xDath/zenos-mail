import { useState, useEffect, useRef } from 'react'
import Layout from '../components/Layout'
import Head from 'next/head'

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
      if (identity.senderEmail) payload.sender_email = identity.senderEmail
      if (identity.senderName) payload.sender_name = identity.senderName
      if (identity.replyTo) payload.reply_to = identity.replyTo

      const res = await fetch('/api/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })
      const data = await res.json()
      if (data.success) {
        showToast({ type: 'success', message: `Sent — ID: ${data.id}` })
        const h = JSON.parse(localStorage.getItem('zenos_history') || '[]')
        h.unshift({ id: data.id, to: toList.join(', '), cc: ccList.join(', '), bcc: bccList.join(', '), subject: payload.subject, htmlMode, attachments: attachments.map(a => a.filename), time: new Date().toISOString() })
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
              {detail.bcc && <div className="detail__field"><span>BCC:</span> {detail.bcc}</div>}
              {detail.attachments?.length > 0 && <div className="detail__field"><span>Attachments:</span> {detail.attachments.join(', ')}</div>}
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

/* ── INBOX PANEL (auto-poll 60s) ─────────────────────────── */
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
          <p style={{ color: 'var(--muted)', fontFamily: 'var(--font-mono)', fontSize: 12, letterSpacing: '0.1em' }}>LOADING…</p>
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

/* ── SETTINGS PANEL ─────────────────────────────────────── */
function SettingsPanel({ showToast }) {
  const [identity, setIdentity] = useState({})
  const [env, setEnv] = useState({})
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    const saved = JSON.parse(localStorage.getItem('zenos_sender_identity') || '{}')
    setIdentity(saved)
    // Load current env config from server
    fetch('/api/config').then(r => r.json()).then(d => {
      if (d.success) setEnv(d.data)
    }).catch(() => {})
  }, [])

  function updateField(field, value) {
    setIdentity(prev => ({ ...prev, [field]: value }))
  }

  function handleSave(e) {
    e.preventDefault()
    setSaving(true)
    localStorage.setItem('zenos_sender_identity', JSON.stringify(identity))
    showToast({ type: 'success', message: 'Sender identity saved' })
    setSaving(false)
  }

  return (
    <div className="panel active" style={{ maxWidth: 600, margin: '0 auto' }}>
      <form className="form" onSubmit={handleSave}>
        <h2 style={{ fontFamily: 'var(--font-heading)', fontWeight: 900, fontSize: 16, letterSpacing: '0.15em', marginBottom: 20, textTransform: 'uppercase', paddingBottom: 8, borderBottom: '1px solid var(--border)' }}>Sender Identity</h2>
        <p style={{ color: 'var(--muted)', fontFamily: 'var(--font-mono)', fontSize: 11, marginBottom: 20, lineHeight: 1.6 }}>
          Override your sender email, name, and reply-to address. Leave blank to use the server defaults.
        </p>

        <div className="form__group">
          <label className="form__label">Sender Email</label>
          <input className="form__input" value={identity.senderEmail || ''} onChange={e => updateField('senderEmail', e.target.value)} placeholder={env.sender_email || 'dwiatma@zenos.studio'} />
        </div>
        <div className="form__group">
          <label className="form__label">Sender Name</label>
          <input className="form__input" value={identity.senderName || ''} onChange={e => updateField('senderName', e.target.value)} placeholder={env.sender_name || 'Dwiatma Tabah Kurniadi'} />
        </div>
        <div className="form__group">
          <label className="form__label">Reply-To</label>
          <input className="form__input" value={identity.replyTo || ''} onChange={e => updateField('replyTo', e.target.value)} placeholder={env.reply_to || 'dwiatma@zenos.studio'} />
        </div>
        <div className="form__group">
          <label className="form__label">Notification Email</label>
          <input className="form__input" value={identity.notifyEmail || ''} onChange={e => updateField('notifyEmail', e.target.value)} placeholder={env.notify_email || 'konodath@gmail.com'} />
        </div>

        <button type="submit" className="btn btn--primary" disabled={saving} style={{ marginTop: 16 }}>
          {saving ? <span className="spinner" /> : 'SAVE IDENTITY'}
        </button>
      </form>

      <div style={{ marginTop: 32, paddingTop: 20, borderTop: '1px solid var(--border)' }}>
        <h2 style={{ fontFamily: 'var(--font-heading)', fontWeight: 900, fontSize: 16, letterSpacing: '0.15em', marginBottom: 12, textTransform: 'uppercase', color: '#E53935' }}>⚠ Domain Verification</h2>
        <p style={{ color: 'var(--muted)', fontFamily: 'var(--font-mono)', fontSize: 11, lineHeight: 1.8 }}>
          To send from <strong>@zenos.studio</strong>, Resend requires domain verification. No VPS needed — just DNS records.
        </p>
        <ol style={{ color: 'var(--text)', fontSize: 12, lineHeight: 2, paddingLeft: 18, fontFamily: 'var(--font-mono)', marginTop: 8 }}>
          <li>Go to <a href="https://resend.com/domains" target="_blank" rel="noopener" style={{ color: 'var(--blue)' }}>resend.com/domains</a></li>
          <li>Click <strong>Add Domain</strong> → enter <code style={{ background: 'var(--bg-secondary)', padding: '1px 4px', fontSize: 10 }}>zenos.studio</code></li>
          <li>Resend gives you 3 DNS records (DKIM + SPF + MX)</li>
          <li>Go to Cloudflare → zenos.studio → DNS → Records</li>
          <li>Add each record exactly as shown</li>
          <li>Wait ~5 min → click <strong>Verify</strong> in Resend</li>
        </ol>
        <p style={{ color: 'var(--muted)', fontFamily: 'var(--font-mono)', fontSize: 10, marginTop: 12 }}>
          Once verified, you can send from <code style={{ background: 'var(--bg-secondary)', padding: '1px 4px', fontSize: 9 }}>dwiatma@zenos.studio</code> or any address @zenos.studio.
        </p>
      </div>
    </div>
  )
}
