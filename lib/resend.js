const API_ROOT = 'https://api.resend.com'

export function validDomain(value) {
  return typeof value === 'string' && value.length <= 253 && /^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/i.test(value)
}

export function validEmail(value) {
  return typeof value === 'string' && value.length <= 254 && /^[^\s@<>(),;:]+@(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/i.test(value)
}

export function sendingReady(domain) {
  if (domain?.capabilities?.sending !== 'enabled') return false
  if (domain.status === 'verified') return true
  if (domain.status !== 'partially_verified' || !Array.isArray(domain.records)) return false
  const required = domain.records.filter(record => record.record === 'DKIM' || record.record === 'SPF')
  return required.length > 0 && required.every(record => record.status === 'verified')
}

export async function resend(path, options = {}) {
  if (!process.env.RESEND_API_KEY) {
    return { ok: false, status: 503, error: 'RESEND_API_KEY belum dikonfigurasi.' }
  }
  try {
    const response = await fetch(`${API_ROOT}${path}`, {
      ...options,
      headers: {
        Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
        ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      },
    })
    const data = await response.json().catch(() => ({}))
    return response.ok
      ? { ok: true, status: response.status, data }
      : { ok: false, status: response.status, error: data.message || data.error || `Resend HTTP ${response.status}` }
  } catch {
    return { ok: false, status: 502, error: 'Tidak bisa menghubungi Resend.' }
  }
}

export function respond(res, result) {
  return res.status(result.status).json(result.ok
    ? { success: true, data: result.data }
    : { success: false, error: result.error })
}
