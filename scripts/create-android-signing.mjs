import { randomBytes } from 'node:crypto'
import { spawnSync } from 'node:child_process'
import fs from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'

const secretDirectory = path.join(os.homedir(), '.zenos-mail')
const keystorePath = path.join(secretDirectory, 'zenos-mail-release.jks')
const recoveryPath = path.join(secretDirectory, 'release-signing.txt')
const propertiesPath = path.resolve('mobile', 'android', 'key.properties')

await fs.mkdir(secretDirectory, { recursive: true })
const exists = async file => fs.access(file).then(() => true).catch(() => false)
if (await exists(keystorePath) || await exists(recoveryPath)) {
  if (!(await exists(propertiesPath))) {
    throw new Error('Release signing exists, but key.properties is missing. Restore it from the recovery file.')
  }
  console.log('Existing Android release signing retained.')
  process.exit(0)
}

const password = randomBytes(24).toString('base64url')
const alias = 'zenos-mail'
const result = spawnSync('keytool.exe', [
  '-genkeypair',
  '-v',
  '-keystore', keystorePath,
  '-storepass', password,
  '-keypass', password,
  '-alias', alias,
  '-keyalg', 'RSA',
  '-keysize', '4096',
  '-validity', '10000',
  '-dname', 'CN=Zenos Mail, OU=Alte Codes, O=Alte Codes, L=Jakarta, ST=Jakarta, C=ID',
  '-noprompt',
], { encoding: 'utf8' })
if (result.status !== 0) throw new Error('keytool failed to create the Android release key.')

const portableKeystorePath = keystorePath.replaceAll('\\', '/')
await fs.writeFile(propertiesPath, [
  `storePassword=${password}`,
  `keyPassword=${password}`,
  `keyAlias=${alias}`,
  `storeFile=${portableKeystorePath}`,
  '',
].join('\n'), { mode: 0o600 })
await fs.writeFile(recoveryPath, [
  'Zenos Mail Android release signing',
  `Keystore: ${keystorePath}`,
  `Alias: ${alias}`,
  `Store password: ${password}`,
  `Key password: ${password}`,
  '',
  'Back up this file and the .jks file together. Losing them prevents signed updates to the same Android app.',
  '',
].join('\n'), { mode: 0o600 })
console.log(`Android release signing created in ${secretDirectory}.`)
