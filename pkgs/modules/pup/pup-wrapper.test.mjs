import assert from 'node:assert/strict'
import {mkdtemp, mkdir, readFile, writeFile} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {dirname, join} from 'node:path'
import {test} from 'node:test'

import {
  buildChildEnv,
  main,
  parseConnectionId,
  readCacheEntry,
  resolveAudience,
  resolveCachePath,
  resolveIdentityToken,
  resolveRuntimeConfig,
  skipsOpenIntAuth,
} from './pup-wrapper.mjs'

const BASE_URL = 'https://connectors.replit.com'
const CONNECTION_ID = 'conn_datadog_abc123'
const PROXY_URL = `${BASE_URL}/api/v2/cli-proxy/datadog/${CONNECTION_ID}`
const NOW = 1_700_000_000_000

async function makeSandbox() {
  const root = await mkdtemp(join(tmpdir(), 'pup-wrapper-'))
  return {
    root,
    env: {
      XDG_CACHE_HOME: root,
      // Force the CLI branch to fail so tests never mint a real identity.
      REPLIT_CLI: join(root, 'missing-replit'),
    },
  }
}

async function seedCache(env, entry) {
  const cachePath = resolveCachePath(env)
  await mkdir(dirname(cachePath), {recursive: true})
  await writeFile(cachePath, JSON.stringify(entry))
  return cachePath
}

async function makeFakePup(root, {exitCode = 0} = {}) {
  const binary = join(root, 'fake-pup')
  const log = join(root, 'fake-pup.log')

  await writeFile(
    binary,
    [
      '#!/bin/sh',
      '{',
      '  echo "args:$*"',
      '  echo "PUP_MOCK_SERVER=${PUP_MOCK_SERVER-<unset>}"',
      '  echo "DD_ACCESS_TOKEN=${DD_ACCESS_TOKEN-<unset>}"',
      '  echo "DD_API_KEY=${DD_API_KEY-<unset>}"',
      '  echo "DD_APP_KEY=${DD_APP_KEY-<unset>}"',
      '  echo "PUP_CONFIG_DIR=${PUP_CONFIG_DIR-<unset>}"',
      `} > ${JSON.stringify(log)}`,
      `exit ${exitCode}`,
      '',
    ].join('\n'),
    {mode: 0o755},
  )

  return {binary, readLog: () => readFile(log, 'utf8')}
}

test('rejects a cache entry whose timestamp is not a number', () => {
  for (const cachedAt of [undefined, null, 'abc', Number.NaN, {}]) {
    const entry = readCacheEntry(
      {connectionId: CONNECTION_ID, proxyUrl: PROXY_URL, cachedAt},
      BASE_URL,
      NOW,
    )
    assert.equal(entry, null, `expected rejection for cachedAt=${String(cachedAt)}`)
  }
})

test('accepts a fresh entry and rejects an expired or future one', () => {
  const entry = {connectionId: CONNECTION_ID, proxyUrl: PROXY_URL}

  assert.deepEqual(readCacheEntry({...entry, cachedAt: NOW - 1_000}, BASE_URL, NOW), {
    connectionId: CONNECTION_ID,
    proxyUrl: PROXY_URL,
  })
  assert.equal(readCacheEntry({...entry, cachedAt: NOW - 5 * 60 * 1000 - 1}, BASE_URL, NOW), null)
  assert.equal(readCacheEntry({...entry, cachedAt: NOW + 1_000}, BASE_URL, NOW), null)
})

test('rejects a cache entry whose connection id disagrees with its URL', () => {
  const entry = readCacheEntry(
    {connectionId: 'conn_datadog_other', proxyUrl: PROXY_URL, cachedAt: NOW},
    BASE_URL,
    NOW,
  )
  assert.equal(entry, null)
})

test('parses a connection id only from a matching CLI proxy URL', () => {
  assert.equal(parseConnectionId(PROXY_URL, BASE_URL), CONNECTION_ID)

  const rejected = [
    `https://evil.example.com/api/v2/cli-proxy/datadog/${CONNECTION_ID}`,
    `http://connectors.replit.com/api/v2/cli-proxy/datadog/${CONNECTION_ID}`,
    `${BASE_URL}/api/v2/cli-proxy/databricks/${CONNECTION_ID}`,
    `${BASE_URL}/api/v2/cli-proxy/datadog/${CONNECTION_ID}?x=1`,
    `${BASE_URL}/api/v2/cli-proxy/datadog/${CONNECTION_ID}#x`,
    `https://user:pass@connectors.replit.com/api/v2/cli-proxy/datadog/${CONNECTION_ID}`,
    `${BASE_URL}/api/v2/cli-proxy/datadog/../../../evil`,
    `${BASE_URL}/api/v2/cli-proxy/datadog/conn_stripe_abc`,
    `${BASE_URL}/api/v2/cli-proxy/datadog/`,
    'not-a-url',
    undefined,
  ]

  for (const proxyUrl of rejected) {
    assert.equal(parseConnectionId(proxyUrl, BASE_URL), null, `expected rejection for ${proxyUrl}`)
  }
})

test('bounds the connection id to the length OpenInt accepts', () => {
  const within = `${BASE_URL}/api/v2/cli-proxy/datadog/conn_datadog_${'a'.repeat(115)}`
  const beyond = `${BASE_URL}/api/v2/cli-proxy/datadog/conn_datadog_${'a'.repeat(116)}`

  assert.ok(parseConnectionId(within, BASE_URL))
  assert.equal(parseConnectionId(beyond, BASE_URL), null)
})

test('honours a connectors base URL that carries a path', () => {
  const baseUrl = 'https://connectors.example.com/base'
  const proxyUrl = `${baseUrl}/api/v2/cli-proxy/datadog/${CONNECTION_ID}`

  assert.equal(parseConnectionId(proxyUrl, baseUrl), CONNECTION_ID)
  assert.equal(parseConnectionId(PROXY_URL, baseUrl), null)
})

test('formats the identity audience exactly like the SDK', () => {
  assert.equal(resolveAudience({}), 'https://connectors.replit.com')
  assert.equal(
    resolveAudience({REPLIT_CONNECTORS_AUDIENCE: 'connectors.example.com'}),
    'https://connectors.example.com',
  )
  // The SDK returns an explicit URL untouched, so any path must survive.
  assert.equal(
    resolveAudience({REPLIT_CONNECTORS_AUDIENCE: 'https://connectors.example.com/base'}),
    'https://connectors.example.com/base',
  )
})

test('falls back to the identity environment variables when the CLI fails', async () => {
  const failing = () => {
    throw new Error('spawn replit ENOENT')
  }

  assert.equal(await resolveIdentityToken({REPL_IDENTITY: 'abc'}, failing), 'repl abc')
  assert.equal(await resolveIdentityToken({WEB_REPL_RENEWAL: 'xyz'}, failing), 'depl xyz')
  await assert.rejects(() => resolveIdentityToken({}, failing), /Replit identity not found/)
})

test('falls back when the identity CLI returns an empty token', async () => {
  const empty = async () => ({stdout: '  \n'})
  assert.equal(await resolveIdentityToken({REPL_IDENTITY: 'abc'}, empty), 'repl abc')
})

test('passes the resolved audience to the identity CLI', async () => {
  const calls = []
  const capture = async (binary, args) => {
    calls.push({binary, args})
    return {stdout: 'minted-token\n'}
  }

  const token = await resolveIdentityToken(
    {REPLIT_CLI: '/custom/replit', REPLIT_CONNECTORS_AUDIENCE: 'https://a.example.com/base'},
    capture,
  )

  assert.equal(token, 'minted-token')
  assert.deepEqual(calls, [
    {
      binary: '/custom/replit',
      args: ['identity', 'create', '--audience', 'https://a.example.com/base'],
    },
  ])
})

test('discovers and caches the proxy URL on a cache miss', async () => {
  const {env} = await makeSandbox()
  let discoverCalls = 0

  const config = await resolveRuntimeConfig({
    env,
    now: NOW,
    discover: async () => {
      discoverCalls += 1
      return {host: PROXY_URL, token: 'sdk-token', connectorName: 'datadog'}
    },
    mint: async () => assert.fail('a cache miss must reuse the SDK token'),
  })

  assert.equal(discoverCalls, 1)
  assert.equal(config.proxyUrl, PROXY_URL)
  assert.equal(config.token, 'sdk-token')

  const cached = JSON.parse(await readFile(resolveCachePath(env), 'utf8'))
  assert.deepEqual(cached, {
    connectionId: CONNECTION_ID,
    proxyUrl: PROXY_URL,
    cachedAt: NOW,
  })
})

test('never writes an identity token to the cache file', async () => {
  const {env} = await makeSandbox()

  await resolveRuntimeConfig({
    env,
    now: NOW,
    discover: async () => ({host: PROXY_URL, token: 'secret-token', connectorName: 'datadog'}),
    mint: async () => 'secret-token',
  })

  const contents = await readFile(resolveCachePath(env), 'utf8')
  assert.ok(!contents.includes('secret-token'))
})

test('reuses a warm cache and mints a fresh identity', async () => {
  const {env} = await makeSandbox()
  await seedCache(env, {connectionId: CONNECTION_ID, proxyUrl: PROXY_URL, cachedAt: NOW})

  const config = await resolveRuntimeConfig({
    env,
    now: NOW + 1_000,
    discover: async () => assert.fail('a warm cache must not call the SDK'),
    mint: async () => 'fresh-token',
  })

  assert.equal(config.proxyUrl, PROXY_URL)
  assert.equal(config.token, 'fresh-token')
})

test('rediscovers when the cached entry is expired or corrupt', async () => {
  const cases = [
    {connectionId: CONNECTION_ID, proxyUrl: PROXY_URL, cachedAt: NOW - 6 * 60 * 1000},
    {connectionId: CONNECTION_ID, proxyUrl: PROXY_URL, cachedAt: 'not-a-number'},
    {connectionId: CONNECTION_ID, proxyUrl: 'https://evil.example.com/x', cachedAt: NOW},
  ]

  for (const entry of cases) {
    const {env} = await makeSandbox()
    await seedCache(env, entry)

    let discoverCalls = 0
    await resolveRuntimeConfig({
      env,
      now: NOW,
      discover: async () => {
        discoverCalls += 1
        return {host: PROXY_URL, token: 'sdk-token', connectorName: 'datadog'}
      },
      mint: async () => assert.fail('a rejected cache must not take the warm path'),
    })

    assert.equal(discoverCalls, 1, `expected rediscovery for ${JSON.stringify(entry)}`)
  }
})

test('rejects an unusable SDK configuration', async () => {
  const {env} = await makeSandbox()

  await assert.rejects(
    () =>
      resolveRuntimeConfig({
        env,
        now: NOW,
        discover: async () => ({host: 'https://evil.example.com/x', token: 'sdk-token'}),
        mint: async () => 'unused',
      }),
    /unusable datadog CLI configuration/,
  )
})

test('replaces Datadog credentials in the child environment', () => {
  const childEnv = buildChildEnv(
    {PATH: '/usr/bin', DD_API_KEY: 'real-key', DD_APP_KEY: 'real-app-key'},
    {proxyUrl: PROXY_URL, token: 'identity-token', configDir: '/tmp/pup-config'},
  )

  assert.equal(childEnv.PUP_MOCK_SERVER, PROXY_URL)
  assert.equal(childEnv.DD_ACCESS_TOKEN, 'identity-token')
  assert.equal(childEnv.PUP_CONFIG_DIR, '/tmp/pup-config')
  assert.equal(childEnv.PATH, '/usr/bin')
  assert.ok(!('DD_API_KEY' in childEnv))
  assert.ok(!('DD_APP_KEY' in childEnv))
})

test('skips OpenInt setup only for commands that need no credentials', () => {
  assert.ok(skipsOpenIntAuth([], {}))
  assert.ok(skipsOpenIntAuth(['--help'], {}))
  assert.ok(skipsOpenIntAuth(['logs', 'search', '--help'], {}))
  assert.ok(skipsOpenIntAuth(['version'], {}))
  assert.ok(skipsOpenIntAuth(['monitors', 'list'], {PUP_SKIP_OPENINT: '1'}))

  assert.ok(!skipsOpenIntAuth(['monitors', 'list'], {}))
  assert.ok(!skipsOpenIntAuth(['logs', 'search', '--query', 'status:error'], {}))
})

test('forwards arguments, exit code, and environment to the real binary', async () => {
  const {root, env} = await makeSandbox()
  const pup = await makeFakePup(root, {exitCode: 3})
  await seedCache(env, {connectionId: CONNECTION_ID, proxyUrl: PROXY_URL, cachedAt: Date.now()})

  const exitCode = await main({
    env: {
      ...env,
      PUP_REAL_BINARY: pup.binary,
      REPL_IDENTITY: 'identity-material',
      DD_API_KEY: 'real-key',
      DD_APP_KEY: 'real-app-key',
    },
    args: ['monitors', 'list'],
  })

  assert.equal(exitCode, 3)

  const log = await pup.readLog()
  assert.match(log, /args:monitors list/)
  assert.match(log, new RegExp(`PUP_MOCK_SERVER=${PROXY_URL}`))
  assert.match(log, /DD_ACCESS_TOKEN=repl identity-material/)
  assert.match(log, /DD_API_KEY=<unset>/)
  assert.match(log, /DD_APP_KEY=<unset>/)
  assert.match(log, /PUP_CONFIG_DIR=\S+/)
})

test('runs authless commands without touching OpenInt', async () => {
  const {root, env} = await makeSandbox()
  const pup = await makeFakePup(root)

  const exitCode = await main({
    env: {...env, PUP_REAL_BINARY: pup.binary},
    args: ['--help'],
  })

  assert.equal(exitCode, 0)
  assert.match(await pup.readLog(), /PUP_MOCK_SERVER=<unset>/)
})

test('fails when the real pup binary is not configured or missing', async () => {
  const {root, env} = await makeSandbox()

  await assert.rejects(() => main({env, args: ['--help']}), /PUP_REAL_BINARY is not set/)
  await assert.rejects(
    () => main({env: {...env, PUP_REAL_BINARY: join(root, 'absent')}, args: ['--help']}),
    /Failed to start pup:/,
  )
})
