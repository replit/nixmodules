import assert from 'node:assert/strict'
import {access, mkdtemp, mkdir, readFile, writeFile} from 'node:fs/promises'
import {tmpdir} from 'node:os'
import {dirname, join} from 'node:path'
import {pathToFileURL} from 'node:url'
import {test} from 'node:test'

import {
  assertSupportedCommand,
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

test('uses the fixed production connectors audience', () => {
  assert.equal(resolveAudience(), 'https://connectors.replit.com')
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
      args: ['identity', 'create', '--audience', 'https://connectors.replit.com'],
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

test('does not trust a caller-provided connectors host', async () => {
  const {env} = await makeSandbox()
  const untrustedEnv = {
    ...env,
    REPLIT_CONNECTORS_HOSTNAME: 'https://evil.example.com',
  }
  await seedCache(untrustedEnv, {
    connectionId: CONNECTION_ID,
    proxyUrl: 'https://evil.example.com/api/v2/cli-proxy/datadog/conn_datadog_abc123',
    cachedAt: NOW,
  })

  let discoverCalls = 0
  await resolveRuntimeConfig({
    env: untrustedEnv,
    now: NOW,
    discover: async () => {
      discoverCalls += 1
      return {host: PROXY_URL, token: 'sdk-token', connectorName: 'datadog'}
    },
    mint: async () => assert.fail('an untrusted cache must not take the warm path'),
  })

  assert.equal(discoverCalls, 1)
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
    {
      PATH: '/usr/bin',
      DD_API_KEY: 'real-key',
      DD_APP_KEY: 'real-app-key',
      DD_ORG: 'customer-org',
      DD_SITE: 'evil.example.com',
      PUP_DOCS_AI_URL: 'https://evil.example.com',
      PUP_SKIP_OPENINT: '1',
    },
    {proxyUrl: PROXY_URL, token: 'identity-token', configDir: '/tmp/pup-config'},
  )

  assert.equal(childEnv.PUP_MOCK_SERVER, PROXY_URL)
  assert.equal(childEnv.DD_ACCESS_TOKEN, 'identity-token')
  assert.equal(childEnv.PUP_CONFIG_DIR, '/tmp/pup-config')
  assert.equal(childEnv.PATH, '/usr/bin')
  assert.ok(!('DD_API_KEY' in childEnv))
  assert.ok(!('DD_APP_KEY' in childEnv))
  assert.ok(!('DD_ORG' in childEnv))
  assert.ok(!('DD_SITE' in childEnv))
  assert.ok(!('PUP_DOCS_AI_URL' in childEnv))
  assert.ok(!('PUP_SKIP_OPENINT' in childEnv))
})

test('skips OpenInt setup only for commands that need no credentials', () => {
  assert.ok(skipsOpenIntAuth([], {}))
  assert.ok(skipsOpenIntAuth(['--help'], {}))
  assert.ok(skipsOpenIntAuth(['logs', 'search', '--help'], {}))
  assert.ok(skipsOpenIntAuth(['version'], {}))

  assert.ok(!skipsOpenIntAuth(['monitors', 'list'], {}))
  assert.ok(!skipsOpenIntAuth(['logs', 'search', '--query', 'status:error'], {}))
  assert.ok(!skipsOpenIntAuth(['monitors', 'list'], {PUP_SKIP_OPENINT: '1'}))
})

test('allows only the approved first-release command surface', () => {
  const allowed = [
    ['logs', 'search'],
    ['logs', 'aggregate'],
    ['metrics', 'query'],
    ['traces', 'search'],
    ['traces', 'aggregate'],
    ['monitors', 'list'],
    ['monitors', 'get', '123'],
    ['dashboards', 'list'],
    ['dashboards', 'get', 'abc'],
    ['dashboards', 'create', '--file', 'dashboard.json'],
    ['dashboards', 'update', 'abc', '--file', 'dashboard.json'],
  ]
  const rejected = [
    ['api', 'https://evil.example.com'],
    ['bits', 'ask', 'hello'],
    ['acp', 'serve'],
    ['auth', 'login'],
    ['extensions', 'run'],
    ['metrics', 'submit'],
    ['monitors', 'delete', '123'],
    ['dashboards', 'delete', 'abc'],
  ]

  for (const args of allowed) {
    assert.doesNotThrow(() => assertSupportedCommand(args))
  }
  assert.doesNotThrow(() =>
    assertSupportedCommand(['--no-agent', '-o', 'json', 'monitors', 'list']),
  )
  for (const args of rejected) {
    assert.throws(() => assertSupportedCommand(args), /Unsupported pup command/)
  }
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

  const configDir = log.match(/PUP_CONFIG_DIR=(\S+)/)?.[1]
  assert.ok(configDir)
  await assert.rejects(() => access(configDir))
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

test('rejects unsupported commands before resolving OpenInt configuration', async () => {
  const {root, env} = await makeSandbox()
  const pup = await makeFakePup(root)

  await assert.rejects(
    () =>
      main({
        env: {
          ...env,
          PUP_REAL_BINARY: pup.binary,
          PUP_SKIP_OPENINT: '1',
        },
        args: ['api', 'https://evil.example.com'],
      }),
    /Unsupported pup command/,
  )
})

test(
  'installed wrapper loads the bundled SDK for cold-cache discovery',
  {skip: !process.env.PUP_INSTALLED_WRAPPER},
  async (t) => {
    const {root, env} = await makeSandbox()
    const replit = join(root, 'replit')
    const pup = await makeFakePup(root)
    const requests = []
    const originalFetch = global.fetch
    const originalReplitCli = process.env.REPLIT_CLI

    await writeFile(replit, '#!/bin/sh\nprintf "test-identity-token\\n"\n', {
      mode: 0o755,
    })
    process.env.REPLIT_CLI = replit
    global.fetch = async (url, init) => {
      const requestUrl = new URL(String(url))
      requests.push({
        url: requestUrl,
        authorization: new Headers(init?.headers).get('Replit-Authentication'),
      })

      if (
        requestUrl.origin === 'https://connectors.replit.com' &&
        requestUrl.pathname === '/api/v2/connection'
      ) {
        return new Response(
          JSON.stringify({
            items: [{id: CONNECTION_ID, connector_name: 'datadog'}],
          }),
          {status: 200, headers: {'Content-Type': 'application/json'}},
        )
      }

      return new Response('unexpected request', {status: 404})
    }
    t.after(() => {
      global.fetch = originalFetch
      if (originalReplitCli === undefined) {
        delete process.env.REPLIT_CLI
      } else {
        process.env.REPLIT_CLI = originalReplitCli
      }
    })

    const installed = await import(
      pathToFileURL(process.env.PUP_INSTALLED_WRAPPER).href,
    )
    const exitCode = await installed.main({
      env: {...env, PUP_REAL_BINARY: pup.binary},
      args: ['monitors', 'list'],
    })

    assert.equal(exitCode, 0)
    assert.equal(requests.length, 1)
    assert.equal(requests[0].url.pathname, '/api/v2/connection')
    assert.equal(
      requests[0].authorization,
      'Bearer test-identity-token',
    )
    assert.match(await pup.readLog(), new RegExp(`PUP_MOCK_SERVER=${PROXY_URL}`))
  },
)
