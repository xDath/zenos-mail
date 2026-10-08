import assert from 'node:assert/strict'
import { createHmac, randomBytes } from 'node:crypto'
import { Readable } from 'node:stream'
import webhook from '../pages/api/webhook/resend.js'
import { sendingReady, validDomain, validEmail } from '../lib/resend.js'

assert.equal(validDomain('alte.codes'), true)
assert.equal(validDomain('bad domain'), false)
assert.equal(validEmail('hello@alte.codes'), true)
assert.equal(validEmail('invalid'), false)
assert.equal(sendingReady({
  status: 'partially_verified',
  capabilities: { sending: 'enabled' },
  records: [
    { record: 'DKIM', status: 'verified' },
    { record: 'SPF', status: 'verified' },
    { record: 'Receiving', status: 'pending' },
  ],
}), true)

const key = randomBytes(32)
process.env.RESEND_WEBHOOK_SECRET = `whsec_${key.toString('base64')}`
delete process.env.TELEGRAM_BOT_TOKEN

async function request(signature) {
  const payload = JSON.stringify({ type: 'email.received', data: { from: 'sender@example.com', to: ['hello@alte.codes'], subject: 'Test' } })
  const id = 'msg_test123'
  const timestamp = Math.floor(Date.now() / 1000).toString()
  const expected = createHmac('sha256', key).update(`${id}.${timestamp}.${payload}`).digest('base64')
  const req = Readable.from([Buffer.from(payload)])
  req.method = 'POST'
  req.headers = {
    'svix-id': id,
    'svix-timestamp': timestamp,
    'svix-signature': `v1,${signature === 'valid' ? expected : randomBytes(32).toString('base64')}`,
  }
  const res = { statusCode: 200, status(code) { this.statusCode = code; return this }, json(body) { this.body = body; return this } }
  await webhook(req, res)
  return res
}

assert.equal((await request('valid')).statusCode, 200)
assert.equal((await request('invalid')).statusCode, 401)
console.log('Security checks passed: domain validation, partial verification, signed webhook')
