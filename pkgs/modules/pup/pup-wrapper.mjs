import {execFile, spawn} from 'node:child_process'
import {mkdtemp, mkdir, readFile, rename, rm, writeFile} from 'node:fs/promises'
import {createRequire} from 'node:module'
import {homedir, tmpdir} from 'node:os'
import {dirname, join, resolve} from 'node:path'
import {pathToFileURL} from 'node:url'
import {promisify} from 'node:util'

const execFileAsync = promisify(execFile)
const require = createRequire(import.meta.url)

const CONNECTOR_NAME = 'datadog'
const DEFAULT_CONNECTORS_HOST = 'connectors.replit.com'
const CONNECTORS_BASE_URL = `https://${DEFAULT_CONNECTORS_HOST}`
const CACHE_TTL_MS = 5 * 60 * 1000

// OpenInt caps CLI proxy path parameters at 128 characters, so bound the id
// rather than accepting an arbitrarily long path segment from the cache file.
const CONNECTION_ID_PATTERN = new RegExp(
  `^conn_${CONNECTOR_NAME}_[a-z0-9_-]{1,115}$`,
  'i',
)

const AUTHLESS_FLAGS = new Set(['--help', '-h', '--version'])
const AUTHLESS_COMMANDS = new Set(['help', 'version'])
const GLOBAL_FLAGS = new Set(['--no-agent', '--read-only'])
const GLOBAL_FLAGS_WITH_VALUE = new Set(['-o', '--output'])
const SUPPORTED_COMMANDS = new Set([
  'logs search',
  'logs aggregate',
  'metrics query',
  'traces search',
  'traces aggregate',
  'monitors list',
  'monitors get',
  'dashboards list',
  'dashboards get',
  'dashboards create',
  'dashboards update',
])

// The SDK has equivalent helpers, but normal pup commands must always reach
// the production connectors host. Honoring a caller-controlled host here could
// send a freshly minted Replit identity to an arbitrary server.
export function resolveAudience() {
  return CONNECTORS_BASE_URL
}

export async function resolveIdentityToken(env, execFn = execFileAsync) {
  try {
    const {stdout} = await execFn(
      env.REPLIT_CLI || 'replit',
      ['identity', 'create', '--audience', resolveAudience()],
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

  const previousAudience = process.env.REPLIT_CONNECTORS_AUDIENCE
  process.env.REPLIT_CONNECTORS_AUDIENCE = CONNECTORS_BASE_URL

  try {
    return await new sdk.ReplitConnectors({
      baseUrl: CONNECTORS_BASE_URL,
    }).getCliConfig(CONNECTOR_NAME)
  } finally {
    if (previousAudience === undefined) {
      delete process.env.REPLIT_CONNECTORS_AUDIENCE
    } else {
      process.env.REPLIT_CONNECTORS_AUDIENCE = previousAudience
    }
  }
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
  const cachePath = resolveCachePath(env)

  const cached = await loadCacheEntry(cachePath, CONNECTORS_BASE_URL, now)
  if (cached) {
    return {proxyUrl: cached.proxyUrl, token: await mint(env), cachePath}
  }

  const config = await discover()
  const connectionId = parseConnectionId(config?.host, CONNECTORS_BASE_URL)
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
  delete childEnv.DD_ORG
  delete childEnv.DD_SITE
  delete childEnv.PUP_DOCS_AI_URL
  delete childEnv.PUP_SKIP_OPENINT

  return childEnv
}

export function skipsOpenIntAuth(args) {
  if (args.length === 0) {
    return true
  }
  if (AUTHLESS_COMMANDS.has(args[0])) {
    return true
  }
  return args.some((arg) => AUTHLESS_FLAGS.has(arg))
}

export function assertSupportedCommand(args) {
  if (skipsOpenIntAuth(args)) {
    return
  }

  let index = 0
  while (true) {
    if (GLOBAL_FLAGS.has(args[index] ?? '')) {
      index += 1
      continue
    }
    if (GLOBAL_FLAGS_WITH_VALUE.has(args[index] ?? '')) {
      index += 2
      continue
    }
    break
  }

  const command = `${args[index] ?? ''} ${args[index + 1] ?? ''}`
  if (!SUPPORTED_COMMANDS.has(command)) {
    throw new Error(
      `Unsupported pup command: ${command.trim()}. This workspace supports logs, metrics, traces, monitor reads, and dashboard read/write operations.`,
    )
  }
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

  if (skipsOpenIntAuth(args)) {
    return runPup(realPup, args, env)
  }

  assertSupportedCommand(args)

  const {proxyUrl, token, cachePath} = await resolveRuntimeConfig({env})
  const configDir = await mkdtemp(join(tmpdir(), 'pup-openint-'))

  try {
    return await runPup(
      realPup,
      args,
      buildChildEnv(env, {proxyUrl, token, configDir}),
    )
  } finally {
    await rm(configDir, {recursive: true, force: true})
  }
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
