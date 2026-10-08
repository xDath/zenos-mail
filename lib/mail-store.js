import { neon } from '@neondatabase/serverless'

let initialized

export function databaseConfigured() {
  return Boolean(process.env.DATABASE_URL || process.env.POSTGRES_URL)
}

function sqlClient() {
  const url = process.env.DATABASE_URL || process.env.POSTGRES_URL
  if (!url) throw new Error('DATABASE_URL belum dikonfigurasi.')
  return neon(url)
}

export async function ensureMailSchema() {
  if (!databaseConfigured()) return false
  if (!initialized) {
    initialized = (async () => {
      const sql = sqlClient()
      await sql.query(`
        CREATE TABLE IF NOT EXISTS zenos_mail_messages (
          id text PRIMARY KEY,
          message_id text,
          direction text NOT NULL CHECK (direction IN ('inbound', 'outbound')),
          from_address text NOT NULL DEFAULT '',
          to_addresses jsonb NOT NULL DEFAULT '[]'::jsonb,
          cc_addresses jsonb NOT NULL DEFAULT '[]'::jsonb,
          bcc_addresses jsonb NOT NULL DEFAULT '[]'::jsonb,
          subject text NOT NULL DEFAULT '',
          text_body text NOT NULL DEFAULT '',
          html_body text NOT NULL DEFAULT '',
          preview text NOT NULL DEFAULT '',
          attachments jsonb NOT NULL DEFAULT '[]'::jsonb,
          search_text text NOT NULL DEFAULT '',
          is_read boolean NOT NULL DEFAULT false,
          occurred_at timestamptz NOT NULL DEFAULT now(),
          archived_at timestamptz NOT NULL DEFAULT now()
        )
      `)
      await sql.query(`
        CREATE INDEX IF NOT EXISTS zenos_mail_messages_occurred_at_idx
        ON zenos_mail_messages (occurred_at DESC)
      `)
      return true
    })().catch(error => {
      initialized = null
      throw error
    })
  }
  return initialized
}

function array(value) {
  if (Array.isArray(value)) return value.filter(item => typeof item === 'string')
  return typeof value === 'string' && value ? [value] : []
}

function plainText(html = '') {
  return String(html)
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/\s+/g, ' ')
    .trim()
}

function preview(value) {
  const normalized = String(value || '').replace(/\s+/g, ' ').trim()
  return normalized.length > 220 ? `${normalized.slice(0, 217)}…` : normalized
}

export async function archiveMessage(message, direction = 'inbound') {
  if (!databaseConfigured()) return null
  await ensureMailSchema()
  const sql = sqlClient()
  const id = message.id || message.email_id
  if (!id) throw new Error('Email tidak memiliki ID.')
  const from = String(message.from || '')
  const to = array(message.to)
  const cc = array(message.cc)
  const bcc = array(message.bcc)
  const subject = String(message.subject || '')
  const text = String(message.text || message.body || '')
  const html = String(message.html || '')
  const bodyText = text || plainText(html)
  const attachments = Array.isArray(message.attachments) ? message.attachments : []
  const occurredAt = message.created_at || new Date().toISOString()
  const searchText = [from, ...to, ...cc, ...bcc, subject, bodyText]
    .join('\n')
    .toLowerCase()

  const rows = await sql.query(`
    INSERT INTO zenos_mail_messages (
      id, message_id, direction, from_address, to_addresses, cc_addresses,
      bcc_addresses, subject, text_body, html_body, preview, attachments,
      search_text, occurred_at
    ) VALUES (
      $1, $2, $3, $4, $5::jsonb, $6::jsonb, $7::jsonb, $8, $9, $10,
      $11, $12::jsonb, $13, $14::timestamptz
    )
    ON CONFLICT (id) DO UPDATE SET
      message_id = EXCLUDED.message_id,
      direction = EXCLUDED.direction,
      from_address = EXCLUDED.from_address,
      to_addresses = EXCLUDED.to_addresses,
      cc_addresses = EXCLUDED.cc_addresses,
      bcc_addresses = EXCLUDED.bcc_addresses,
      subject = EXCLUDED.subject,
      text_body = CASE WHEN EXCLUDED.text_body <> '' THEN EXCLUDED.text_body ELSE zenos_mail_messages.text_body END,
      html_body = CASE WHEN EXCLUDED.html_body <> '' THEN EXCLUDED.html_body ELSE zenos_mail_messages.html_body END,
      preview = CASE WHEN EXCLUDED.preview <> '' THEN EXCLUDED.preview ELSE zenos_mail_messages.preview END,
      attachments = EXCLUDED.attachments,
      search_text = CASE WHEN EXCLUDED.search_text <> '' THEN EXCLUDED.search_text ELSE zenos_mail_messages.search_text END,
      occurred_at = EXCLUDED.occurred_at,
      archived_at = now()
    RETURNING id
  `, [
    id,
    message.message_id || null,
    direction,
    from,
    JSON.stringify(to),
    JSON.stringify(cc),
    JSON.stringify(bcc),
    subject,
    text,
    html,
    preview(bodyText),
    JSON.stringify(attachments),
    searchText,
    occurredAt,
  ])
  return rows[0] || null
}

function mapRow(row, includeBody = false) {
  return {
    id: row.id,
    message_id: row.message_id,
    direction: row.direction,
    from: row.from_address,
    to: row.to_addresses || [],
    cc: row.cc_addresses || [],
    bcc: row.bcc_addresses || [],
    subject: row.subject,
    preview: row.preview,
    attachments: row.attachments || [],
    is_read: row.is_read,
    created_at: row.occurred_at,
    ...(includeBody ? { text: row.text_body, html: row.html_body } : {}),
  }
}

export async function listMessages({ query = '', domain = '', direction = 'inbound', limit = 50 } = {}) {
  await ensureMailSchema()
  const sql = sqlClient()
  const filters = ['direction = $1']
  const params = [direction]
  if (query.trim()) {
    params.push(`%${query.trim().toLowerCase()}%`)
    filters.push(`search_text LIKE $${params.length}`)
  }
  if (domain.trim()) {
    params.push(`%@${domain.trim().toLowerCase()}%`)
    filters.push(`lower(to_addresses::text) LIKE $${params.length}`)
  }
  params.push(Math.max(1, Math.min(Number(limit) || 50, 100)))
  const rows = await sql.query(`
    SELECT id, message_id, direction, from_address, to_addresses, cc_addresses,
      bcc_addresses, subject, preview, attachments, is_read, occurred_at
    FROM zenos_mail_messages
    WHERE ${filters.join(' AND ')}
    ORDER BY occurred_at DESC
    LIMIT $${params.length}
  `, params)
  return rows.map(row => mapRow(row))
}

export async function getMessage(id) {
  await ensureMailSchema()
  const sql = sqlClient()
  const rows = await sql.query(`
    SELECT * FROM zenos_mail_messages WHERE id = $1 LIMIT 1
  `, [id])
  return rows[0] ? mapRow(rows[0], true) : null
}

export async function markMessageRead(id) {
  await ensureMailSchema()
  const sql = sqlClient()
  const rows = await sql.query(`
    UPDATE zenos_mail_messages SET is_read = true WHERE id = $1 RETURNING id
  `, [id])
  return Boolean(rows[0])
}
