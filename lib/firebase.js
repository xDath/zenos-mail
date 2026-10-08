import { cert, getApps, initializeApp } from 'firebase-admin/app'
import { getMessaging } from 'firebase-admin/messaging'

let messaging

function serviceAccount() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim()
  if (!raw) return null
  try {
    const account = JSON.parse(raw)
    if (!account.project_id || !account.client_email || !account.private_key) return null
    return account
  } catch {
    return null
  }
}

export function firebaseConfigured() {
  return Boolean(serviceAccount())
}

export function firebaseMessaging() {
  if (messaging) return messaging
  const account = serviceAccount()
  if (!account) return null
  const app = getApps()[0] || initializeApp({ credential: cert(account) })
  messaging = getMessaging(app)
  return messaging
}
