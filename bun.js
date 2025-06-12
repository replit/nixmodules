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
	if (!res.ok) throw new Error(`Failed to fetch Bun: ${response.statusText}`);

	const hash = crypto.createHash('sha256');
	// BROKE WHY?
	hash.update(await res.arrayBuffer());
	const base64Hash = hash.digest('base64');
	const nixHash = `sha256-${base64Hash}`;

	const updatedNixFile = nixFileText
		.replace(/version = "\d+\.\d+\.\d+"/, `version = "${version}"`)
		.replace(/sha256-[^"]+/g, nixHash);

	await Bun.write(nixFile, updatedNixFile);
	console.log(`Updated default.nix with version ${version} and hash ${nixHash}`);
}