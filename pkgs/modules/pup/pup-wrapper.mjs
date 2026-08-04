import {spawn} from 'node:child_process'

const realPup = process.env.PUP_REAL_BINARY

if (!realPup) {
  process.stderr.write('PUP_REAL_BINARY is not set\n')
  process.exit(1)
}

const child = spawn(realPup, process.argv.slice(2), {
  env: process.env,
  stdio: 'inherit',
})

child.on('error', (error) => {
  process.stderr.write(`Failed to start pup: ${error.message}\n`)
  process.exit(1)
})

child.on('close', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal)
    return
  }

  process.exit(code ?? 1)
})
