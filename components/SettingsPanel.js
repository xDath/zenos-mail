import { useEffect, useState } from 'react'

function domainCaption(domain) {
  if (domain.capabilities?.receiving === 'enabled' && domain.status === 'partially_verified') return 'SEND READY · INBOX PENDING'
  if (domain.capabilities?.receiving === 'enabled' && domain.status === 'verified') return 'SEND + RECEIVE'
  if (domain.status === 'verified') return 'SEND READY'
  return 'SETUP REQUIRED'
}

export default function SettingsPanel({ showToast }) {
  const [identity, setIdentity] = useState({})
  const [env, setEnv] = useState({})
  const [domains, setDomains] = useState([])
  const [selected, setSelected] = useState(null)
  const [name, setName] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [notification, setNotification] = useState(null)
  const [testingNotification, setTestingNotification] = useState(false)

  async function loadDomains(pickId) {
    const result = await fetch('/api/domains').then(r => r.json())
    if (!result.success) throw new Error(result.error || 'Gagal memuat domain')
    const list = result.data?.data || []
    setDomains(list)
    const domain = list.find(d => d.id === pickId) || list.find(d => d.id === selected?.id) || list[0]
    if (!domain) return setSelected(null)
    const detail = await fetch(`/api/domains/${domain.id}`).then(r => r.json())
    if (!detail.success) throw new Error(detail.error || 'Gagal memuat detail domain')
    setSelected(detail.data)
  }

  useEffect(() => {
    try { setIdentity(JSON.parse(localStorage.getItem('zenos_sender_identity') || '{}')) } catch {}
    fetch('/api/config').then(r => r.json()).then(d => { if (d.success) setEnv(d.data) }).catch(() => {})
    fetch('/api/notifications').then(r => r.json()).then(setNotification).catch(() => {})
    loadDomains().catch(err => setError(err.message))
  }, [])

  async function testNotification() {
    setTestingNotification(true)
    try {
      const response = await fetch('/api/notifications', { method: 'POST' })
      const result = await response.json()
      if (!result.success) throw new Error(result.error || 'Gagal mengirim tes')
      showToast({ type: 'success', message: 'Tes push dikirim. Cek notifikasi di Android.' })
    } catch (err) {
      showToast({ type: 'error', message: err.message })
    }
    setTestingNotification(false)
  }

  async function addDomain(event) {
    event.preventDefault()
    setBusy(true); setError('')
    try {
      const result = await fetch('/api/domains', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ name }) }).then(r => r.json())
      if (!result.success) throw new Error(result.error)
      setName('')
      await loadDomains(result.data.id)
      showToast({ type: 'success', message: 'Domain ditambahkan. Pasang DNS lalu verifikasi.' })
    } catch (err) { setError(err.message) }
    setBusy(false)
  }

  async function domainAction(method, body) {
    if (!selected) return
    setBusy(true); setError('')
    try {
      const result = await fetch(`/api/domains/${selected.id}`, { method, headers: { 'Content-Type': 'application/json' }, ...(body ? { body: JSON.stringify(body) } : {}) }).then(r => r.json())
      if (!result.success) throw new Error(result.error)
      await loadDomains(selected.id)
      showToast({ type: 'success', message: method === 'POST' ? 'Pemeriksaan DNS dimulai. Refresh status beberapa saat lagi.' : 'Pengaturan inbox diperbarui.' })
    } catch (err) { setError(err.message) }
    setBusy(false)
  }

  function saveIdentity(event) {
    event.preventDefault()
    localStorage.setItem('zenos_sender_identity', JSON.stringify(identity))
    showToast({ type: 'success', message: 'Identitas pengirim disimpan di browser ini.' })
  }

  return <div className="panel active settings">
    <div className="section-intro"><span className="eyebrow">WORKSPACE / 04</span><h1>Kelola email.</h1><p>Tambah domain, pasang DNS, lalu gunakan alamat yang kamu butuhkan.</p></div>
    <section className="settings-card">
      <div className="settings-card__heading"><div><span className="eyebrow">01 / DOMAINS</span><h2>Domain kamu</h2></div><button type="button" className="btn btn--ghost btn--small" onClick={() => loadDomains(selected?.id).catch(err => setError(err.message))}>REFRESH</button></div>
      <form className="domain-add" onSubmit={addDomain}><input className="form__input" aria-label="Nama domain baru" value={name} onChange={e => setName(e.target.value)} placeholder="alte.codes" required /><button className="btn btn--primary" disabled={busy}>+ ADD DOMAIN</button></form>
      {error && <p className="inline-error" role="alert">{error}</p>}
      <div className="domain-list">{domains.map(d => <button type="button" key={d.id} className={`domain-item${selected?.id === d.id ? ' active' : ''}`} onClick={() => fetch(`/api/domains/${d.id}`).then(r => r.json()).then(result => result.success ? setSelected(result.data) : setError(result.error)).catch(err => setError(err.message))}><span><strong>{d.name}</strong><small>{domainCaption(d)}</small></span><em className={`status-pill ${d.status === 'verified' ? 'verified' : ''}`}>{d.status.replaceAll('_', ' ')}</em></button>)}</div>
      {!domains.length && !error && <p className="muted-note">Belum ada domain di akun Resend ini.</p>}
      {selected && <div className="domain-detail"><div className="domain-detail__top"><div><span className="eyebrow">DNS SETUP</span><h3>{selected.name}</h3></div><span className={`status-pill ${selected.status === 'verified' ? 'verified' : ''}`}>{selected.status}</span></div><p className="muted-note">Salin record berikut ke DNS provider domain ini. Nama record bisa relatif ke domain; ikuti format provider kamu.</p><div className="dns-table"><div className="dns-row dns-row--head"><span>TYPE</span><span>NAME</span><span>VALUE</span><span>STATUS</span></div>{(selected.records || []).map((record, index) => <div className="dns-row" key={`${record.type}-${record.name}-${index}`}><span>{record.type}{record.priority ? ` · ${record.priority}` : ''}</span><code title={record.name}>{record.name}</code><code title={record.value}>{record.value}</code><span>{record.status || '—'}</span></div>)}</div><div className="domain-actions"><button type="button" className="btn btn--primary" disabled={busy} onClick={() => domainAction('POST')}>VERIFY DNS</button><button type="button" className="btn btn--ghost" disabled={busy} onClick={() => domainAction('PATCH', { receiving: selected.capabilities?.receiving !== 'enabled' })}>{selected.capabilities?.receiving === 'enabled' ? 'DISABLE INBOX' : 'ENABLE INBOX'}</button></div><p className="muted-note">Untuk menerima email, aktifkan inbox dan pasang record MX penerimaan yang muncul. Jangan ganti MX utama jika domain ini memakai penyedia inbox lain.</p></div>}
    </section>
    <section className="settings-card"><span className="eyebrow">02 / DEFAULTS</span><h2>Identitas pengirim</h2><p className="muted-note">Nama dan reply-to berlaku untuk browser ini. Alamat pengirim dipilih di halaman Send.</p><form className="form" onSubmit={saveIdentity}><div className="form__group"><label className="form__label" htmlFor="sender-name">Sender name</label><input id="sender-name" className="form__input" value={identity.senderName || ''} onChange={e => setIdentity({ ...identity, senderName: e.target.value })} placeholder={env.sender_name || 'Your name'} /></div><div className="form__group"><label className="form__label" htmlFor="reply-to">Reply-to</label><input id="reply-to" type="email" className="form__input" value={identity.replyTo || ''} onChange={e => setIdentity({ ...identity, replyTo: e.target.value })} placeholder={env.reply_to || 'reply@example.com'} /></div><button className="btn btn--primary">SAVE IDENTITY</button></form></section>
    <section className="settings-card">
      <span className="eyebrow">03 / NOTIFICATIONS</span>
      <h2>Push Android</h2>
      <p className="muted-note">Email masuk akan memunculkan notifikasi di aplikasi ntfy, tanpa mengirim email tambahan. Isi push hanya pemberitahuan umum karena topik gratis ntfy bersifat publik.</p>
      {notification?.configured ? <>
        <p className="muted-note">Pasang <a href="https://play.google.com/store/apps/details?id=io.heckel.ntfy" target="_blank" rel="noreferrer">ntfy untuk Android</a>, izinkan notifikasi, lalu langganan topik ini:</p>
        <div className="notification-topic"><code>{notification.topic}</code><button type="button" className="btn btn--ghost btn--small" onClick={() => navigator.clipboard.writeText(notification.topic).then(() => showToast({ type: 'success', message: 'Topik disalin.' })).catch(() => showToast({ type: 'error', message: 'Gagal menyalin topik.' }))}>COPY</button></div>
        <div className="domain-actions"><a className="btn btn--ghost" href={`ntfy://ntfy.sh/${notification.topic}?display=Zenos%20Mail`}>BUKA DI NTFY</a><button type="button" className="btn btn--primary" disabled={testingNotification} onClick={testNotification}>{testingNotification ? 'MENGIRIM…' : 'KIRIM TES PUSH'}</button></div>
        <p className="muted-note">Gunakan topik ini hanya di perangkat kamu. Setelah tes berhasil, setiap email masuk akan memicu push prioritas tinggi.</p>
      </> : <p className="muted-note">Belum aktif. Set <code>NTFY_TOPIC</code> di environment Vercel dengan nilai acak 32–64 karakter, lalu deploy ulang.</p>}
    </section>
  </div>
}
