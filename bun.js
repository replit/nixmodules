import crypto from 'crypto';

const nixFile = Bun.file('pkgs/bun/default.nix');
const nixFileText = await nixFile.text();

const repoOwner = 'oven-sh';
const repoName = 'bun';

try {
	const latestVersion = await getLatestVersion();
	const currentVersion = readCurrentVersion();

	console.log(`Current version: ${currentVersion}`);
	console.log(`Latest version: ${latestVersion}`);

	if (currentVersion !== latestVersion) {
		console.log(`Updating to latest version ${latestVersion}`);
		await updateNixFile(latestVersion);
	} else {
		console.log('Already up-to-date');
	}
} catch (error) {
	console.error(`Error: ${error}`);
}

async function getLatestVersion() {
	const res = await fetch(`https://api.github.com/repos/${repoOwner}/${repoName}/releases/latest`);
	if (!res.ok) throw new Error(`Failed to fetch latest release: ${response.statusText}`);

	const data = await res.json();
	return data.tag_name.replace('bun-v', '');
}

function readCurrentVersion() {
	return nixFileText.match(/version = "([^"]+)"/)[1];
}

async function updateNixFile(version) {
	const bunUrl = `https://github.com/${repoOwner}/${repoName}/releases/download/bun-v${version}/bun-linux-x64.zip`;

	const res = await fetch(bunUrl);
	if (!res.ok) throw new Error(`Failed to fetch Bun: ${res.statusText}`);

	const hash = crypto.createHash('sha256');
	const data = await res.arrayBuffer();
	hash.update(Buffer.from(data));
	const base64Hash = hash.digest('base64');
	const nixHash = `sha256-${base64Hash}`;

	const updatedNixFile = nixFileText
		.replace(/version = "\d+\.\d+\.\d+"/, `version = "${version}"`)
		.replace(/sha256-[^"]+/g, nixHash);

	await Bun.write(nixFile, updatedNixFile);
	console.log(`Updated default.nix with version ${version} and hash ${nixHash}`);

	await runGitCommand(['add', 'pkgs/bun/default.nix']);
	await runGitCommand(['switch', 'main']);
	// Identity of the committer
	await runGitCommand(['config', 'user.email', '83923848+7heMech@users.noreply.github.com']);
	await runGitCommand(['config', 'user.name', "7heMech's Bun Updater"]);
	await runGitCommand(['commit', '-m', `Update Bun to version ${version}`]);
	await runGitCommand(['push', 'origin', 'main']);

	const commitHash = await runGitCommand(['rev-parse', 'HEAD']);
	console.log(`Committed changes to main branch: ${commitHash}`);
	console.log('Switching back to bun-updater branch');
	await runGitCommand(['switch', 'bun-updater']);
	await runGitCommand(['cherry-pick', commitHash.trim()]);
	await runGitCommand(['push', 'origin', 'bun-updater']);
	console.log('Successfully updated Bun and pushed changes to bun-updater branch');
}

async function runGitCommand(args) {
	const proc = Bun.spawn(['git', ...args], {
		cwd: process.cwd(),
		stdout: 'pipe',
		stderr: 'pipe'
	});

	const result = await proc.exited;
	if (result !== 0) {
		const stderr = await new Response(proc.stderr).text();
		throw new Error(`Git command failed: git ${args.join(' ')}\n${stderr}`);
	}

	return await new Response(proc.stdout).text();
}