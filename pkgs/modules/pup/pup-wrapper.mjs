import {execFile, spawn} from 'node:child_process'
import {mkdir, readFile, rename, rm, writeFile} from 'node:fs/promises'
import {createRequire} from 'node:module'
import {homedir} from 'node:os'
import {dirname, join, resolve} from 'node:path'
import {pathToFileURL} from 'node:url'
import {promisify} from 'node:util'

const execFileAsync = promisify(execFile)
const require = createRequire(import.meta.url)

const CONNECTOR_NAME = 'datadog'
const DEFAULT_CONNECTORS_HOST = 'connectors.replit.com'
const CACHE_TTL_MS = 5 * 60 * 1000

// OpenInt caps CLI proxy path parameters at 128 characters, so bound the id
// rather than accepting an arbitrarily long path segment from the cache file.
const CONNECTION_ID_PATTERN = new RegExp(
  `^conn_${CONNECTOR_NAME}_[a-z0-9_-]{1,115}$`,
  'i',
)

const AUTHLESS_FLAGS = new Set(['--help', '-h', '--version'])
const AUTHLESS_COMMANDS = new Set(['help', 'version'])

// resolveBaseUrl, resolveAudience, and resolveIdentityToken mirror private
// helpers in @replit/connectors-sdk, which exports only ReplitConnectors. Keep
// them identical: a warm-cache command mints its token here and a cold-cache
// command gets one from the SDK, so the two must be interchangeable.
function resolveBaseUrl(env) {
  const hostname = env.REPLIT_CONNECTORS_HOSTNAME
  if (hostname) {
    if (hostname.startsWith('http://') || hostname.startsWith('https://')) {
      return hostname
    }
    return `https://${hostname}`
  }
  return `https://${DEFAULT_CONNECTORS_HOST}`
}

export function resolveAudience(env) {
  const audience = env.REPLIT_CONNECTORS_AUDIENCE
  if (audience) {
    if (audience.startsWith('http://') || audience.startsWith('https://')) {
      return audience
    }
    return `https://${audience}`
  }
  return `https://${DEFAULT_CONNECTORS_HOST}`
}

export async function resolveIdentityToken(env, execFn = execFileAsync) {
  try {
    const {stdout} = await execFn(
      env.REPLIT_CLI || 'replit',
      ['identity', 'create', '--audience', resolveAudience(env)],
      {encoding: 'utf8', env},
    )
    const token = stdout.trim()
    if (token) {
      return token
    }
  } catch {
    // The CLI is unavailable in some runtimes; fall back to the env strategies.
  }

  if (env.REPL_IDENTITY) {
    return `repl ${env.REPL_IDENTITY}`
  }
  if (env.WEB_REPL_RENEWAL) {
    return `depl ${env.WEB_REPL_RENEWAL}`
  }

  throw new Error(
    'Replit identity not found. Could not run `replit identity create`, and ' +
      'neither REPL_IDENTITY nor WEB_REPL_RENEWAL is set. Are you running ' +
      'inside a Repl?',
  )
}

export function resolveCachePath(env) {
  const root = env.XDG_CACHE_HOME || join(env.HOME || homedir(), '.cache')
  return join(root, 'replit', 'pup-openint.json')
}

/**
 * Return the connection id encoded in an OpenInt CLI proxy URL, or null when
 * the URL is not one. The cache file is user-writable, so this also stops a
 * tampered entry from redirecting the Replit identity to another host.
 */
export function parseConnectionId(proxyUrl, baseUrl) {
  let base
  let proxy
  try {
    base = new URL(baseUrl)
    proxy = new URL(proxyUrl)
  } catch {
    return null
  }

  const prefix = `${base.pathname.replace(/\/$/, '')}/api/v2/cli-proxy/${CONNECTOR_NAME}/`

  if (
    proxy.origin !== base.origin ||
    proxy.username ||
    proxy.password ||
    proxy.search ||
    proxy.hash ||
    !proxy.pathname.startsWith(prefix)
  ) {
    return null
  }

  const connectionId = decodeURIComponent(proxy.pathname.slice(prefix.length))
  return CONNECTION_ID_PATTERN.test(connectionId) ? connectionId : null
}

export function readCacheEntry(raw, baseUrl, now) {
  if (raw === null || typeof raw !== 'object') {
    return null
  }

  // Every comparison against NaN is false, so a non-numeric timestamp would
  // slip past the age check below and pin the cache entry forever.
  if (typeof raw.cachedAt !== 'number' || !Number.isFinite(raw.cachedAt)) {
    return null
  }

  const age = now - raw.cachedAt
  if (age < 0 || age > CACHE_TTL_MS) {
    return null
  }

  const connectionId = parseConnectionId(raw.proxyUrl, baseUrl)
  if (!connectionId || connectionId !== raw.connectionId) {
    return null
  }

  return {connectionId, proxyUrl: raw.proxyUrl}
}

async function loadCacheEntry(cachePath, baseUrl, now) {
  try {
    const raw = JSON.parse(await readFile(cachePath, 'utf8'))
    return readCacheEntry(raw, baseUrl, now)
  } catch {
    return null
  }
}

async function saveCacheEntry(cachePath, entry) {
  await mkdir(dirname(cachePath), {recursive: true, mode: 0o700})

  const temporaryPath = `${cachePath}.${process.pid}.tmp`
  try {
    await writeFile(temporaryPath, `${JSON.stringify(entry)}\n`, {mode: 0o600})
    await rename(temporaryPath, cachePath)
  } catch (error) {
    await rm(temporaryPath, {force: true})
    throw error
  }
}

async function discoverCliConfig() {
  let sdk
  try {
    sdk = require('@replit/connectors-sdk')
  } catch (error) {
    throw new Error(
      `Could not load @replit/connectors-sdk: ${error.message}. The pup module ` +
        'must ship the SDK beside the wrapper.',
    )
  }

  return new sdk.ReplitConnectors().getCliConfig(CONNECTOR_NAME)
}

/**
 * Resolve the proxy URL and a Replit identity for one pup invocation. Only the
 * non-secret proxy URL is cached; the identity is short-lived and always minted
 * fresh.
 */
export async function resolveRuntimeConfig({
  env,
  now = Date.now(),
  discover = discoverCliConfig,
  mint = resolveIdentityToken,
}) {
  const baseUrl = resolveBaseUrl(env)
  const cachePath = resolveCachePath(env)

  const cached = await loadCacheEntry(cachePath, baseUrl, now)
  if (cached) {
    return {proxyUrl: cached.proxyUrl, token: await mint(env), cachePath}
  }

  const config = await discover()
  const connectionId = parseConnectionId(config?.host, baseUrl)
  if (!connectionId || typeof config.token !== 'string' || !config.token) {
    throw new Error(
      `The Connectors SDK returned an unusable ${CONNECTOR_NAME} CLI configuration.`,
    )
  }

  try {
    await saveCacheEntry(cachePath, {
      connectionId,
      proxyUrl: config.host,
      cachedAt: now,
    })
  } catch (error) {
    process.stderr.write(
      `pup: could not cache the OpenInt proxy URL: ${error.message}\n`,
    )
  }

  return {proxyUrl: config.host, token: config.token, cachePath}
}

export function buildChildEnv(env, {proxyUrl, token, configDir}) {
  const childEnv = {
    ...env,
    PUP_MOCK_SERVER: proxyUrl,
    DD_ACCESS_TOKEN: token,
    // Isolate pup from ~/.config/pup/config.yaml, which can carry Datadog keys.
    PUP_CONFIG_DIR: configDir,
  }

  // pup falls back to these for endpoints that reject bearer tokens. Leaving a
  // caller's real Datadog keys in place would forward them through the proxy.
  delete childEnv.DD_API_KEY
  delete childEnv.DD_APP_KEY

  return childEnv
}

export function skipsOpenIntAuth(args, env) {
  if (env.PUP_SKIP_OPENINT === '1' || args.length === 0) {
    return true
  }
  if (AUTHLESS_COMMANDS.has(args[0])) {
    return true
  }
  return args.some((arg) => AUTHLESS_FLAGS.has(arg))
}

function runPup(binary, args, env) {
  return new Promise((resolveExit, reject) => {
    const child = spawn(binary, args, {env, stdio: 'inherit'})

    child.once('error', (error) => {
      reject(new Error(`Failed to start pup: ${error.message}`))
    })

    child.once('close', (code, signal) => {
      if (signal) {
        process.kill(process.pid, signal)
        return
      }
      resolveExit(code ?? 1)
    })
  })
}

export async function main({env = process.env, args = process.argv.slice(2)} = {}) {
  const realPup = env.PUP_REAL_BINARY
  if (!realPup) {
    throw new Error('PUP_REAL_BINARY is not set')
  }

  if (skipsOpenIntAuth(args, env)) {
    return runPup(realPup, args, env)
  }

  const {proxyUrl, token, cachePath} = await resolveRuntimeConfig({env})
  const configDir = join(dirname(cachePath), 'pup-config')
  await mkdir(configDir, {recursive: true, mode: 0o700})

  return runPup(realPup, args, buildChildEnv(env, {proxyUrl, token, configDir}))
}

const isDirectInvocation =
  process.argv[1] !== undefined &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href

if (isDirectInvocation) {
  main().then(
    (code) => {
      process.exitCode = code
    },
    (error) => {
      process.stderr.write(`${error.message}\n`)
      process.exitCode = 1
    },
  )
}
