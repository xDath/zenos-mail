import { neon } from '@neondatabase/serverless'
import {
  archiveMessage,
  getMessage,
  listMessages,
  markMessageRead,
  registerPushDevice,
  unregisterPushDevice,
} from '../lib/mail-store.js'

if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required')

const id = `test-search-${Date.now()}`
const token = `test:${'a'.repeat(100)}`
const sql = neon(process.env.DATABASE_URL)

try {
  await archiveMessage({
    id,
    from: 'Anda Purnama <anda@example.com>',
    to: ['hello@zenos.studio'],
    subject: 'Catatan Andalusia',
    text: 'Isi membahas Anda dan Andalusia secara lengkap.',
    attachments: [{ filename: 'catatan.pdf' }],
  })
  await archiveMessage({
    id,
    from: 'Anda Purnama <anda@example.com>',
    to: ['hello@zenos.studio'],
    subject: 'Catatan Andalusia',
  })
  const hits = await listMessages({ query: 'anda' })
  const bodyHits = await listMessages({ query: 'secara lengkap' })
  const detail = await getMessage(id)
  const marked = await markMessageRead(id)
  const registered = await registerPushDevice(token)
  await unregisterPushDevice(token)

  if (!hits.some(message => message.id === id)) throw new Error('Substring search failed')
  if (!bodyHits.some(message => message.id === id)) throw new Error('Archived body search was not preserved')
  if (detail?.subject !== 'Catatan Andalusia') throw new Error('Message detail failed')
  if (detail?.attachments?.[0]?.filename !== 'catatan.pdf') throw new Error('Attachment metadata was not preserved')
  if (!marked) throw new Error('Mark read failed')
  if (!registered) throw new Error('Device registration failed')

  console.log('Database archive, substring search, read state, and device registration passed.')
} finally {
  await sql.query("DELETE FROM zenos_mail_messages WHERE id LIKE 'test-search-%'")
  await sql.query("DELETE FROM zenos_push_devices WHERE token LIKE 'test:%'")
}
