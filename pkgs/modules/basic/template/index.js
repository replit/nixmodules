const { app, BrowserWindow, ipcMain } = require("electron");
const readline = require("readline");
const fs = require("fs/promises");

var options = require("minimist")(process.argv.slice(3));

let win;

function createWindow() {
	win = new BrowserWindow({
		frame: false,
		fullscreen: true,
		webPreferences: {
			nodeIntegration: true,
			contextIsolation: false,
		},
	});

	win.loadFile("index.html");
}

app.whenReady().then(() => {
	createWindow();
});

app.on("window-all-closed", () => {
	app.quit();
});

ipcMain.on("ready", async (event) => {
	let code = "";
	if (options._.length > 0) {
		code = (await fs.readFile(options._[0])).toString();
	}
	event.reply("evaluate", { code });
});

ipcMain.on("output", (event, output) => {
	process.stdout.write(output);
});

ipcMain.on("input", async (event, output) => {
	process.stdout.write(" ");
	const rl = readline.createInterface({
		input: process.stdin,
		output: process.stdout,
		terminal: false,
	});
	rl.on("line", (input) => {
		event.reply("write", input);
		rl.close();
	});
});

let repl;
ipcMain.on("result", async (event, { error }) => {
	if (error) {
		console.log("Error: ", error);
	}

	if (!repl) {
		repl = readline.createInterface({
			input: process.stdin,
			output: process.stdout,
			prompt: `${options.ps1} ` || "> ",
		});

		repl.on("line", (code) => {
			repl.pause();
			event.reply("evaluate", { code });
		});
	}

	repl.prompt();
});
