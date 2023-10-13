const fs = require('node:fs');
const path = require('node:path');
const { spawn } = require('node:child_process');

const args = process.argv.slice(1);

let runPackageJsonScript = null;
const runPackageJsonScriptFlag = '--run-package-json-script';
let runScript = null;
const runScriptFlag = '--run-script';

const checkPackageJsonScript = () => {
  if (!runPackageJsonScript) {
    console.error(`No argument provided for ${runPackageJsonScriptFlag}`);
    console.info(
      `hint: add \`${runPackageJsonScriptFlag} "bun run"\` to your run command`
    );
    process.exit(1);
  }
};

const checkRunScript = () => {
  if (!runScript) {
    console.error(`No argument provided for ${runScriptFlag}`);
    console.info(`hint: add \`${runScriptFlag} "bun"\` to your run command`);
    process.exit(1);
  }
};

while (args.length > 0) {
  const flag = args.shift();

  if (flag.startsWith('--run-package-json-script')) {
    runPackageJsonScript = args.shift();
  } else if (flag.startsWith('--run-script')) {
    runScript = args.shift();
  }
}

const packageJsonPath = path.join(process.cwd(), 'package.json');
if (!fs.existsSync(packageJsonPath)) {
  console.error('No package.json found');
  process.exit(1);
}

const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

const hasScripts = Boolean(packageJson.scripts);

let cmd = null;
if (hasScripts && packageJson.scripts['replit-dev']) {
  checkPackageJsonScript();
  cmd = [runPackageJsonScript, 'replit-dev'];
} else if (hasScripts && packageJson.scripts['dev']) {
  checkPackageJsonScript();
  cmd = [runPackageJsonScript, 'dev'];
} else if (process.env['file']) {
  checkRunScript();
  cmd = [runScript, process.env['file']];
} else if (packageJson['main']) {
  checkRunScript();
  cmd = [runScript, packageJson['main']];
} else {
  console.error('Nothing to run.');
  process.exit(1);
}

console.info(`+ ${cmd.join(' ')}`);

spawn(cmd[0], cmd.slice(1), {
	stdio: 'inherit',
	cwd: process.cwd(),
	shell: false,
})
