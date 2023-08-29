const { ipcRenderer } = require("electron");
const Display = require("./basic/display.js");
const sound = require("./basic/sound.js");
const Basic = require("./basic/pg-basic.js");

ipcRenderer.on("stop", () => {
	if (basic) basic.end();
	sound.close();
});

ipcRenderer.on("evaluate", (event, { code }) => {
	const oldWrapper = document.getElementById("basic_display");
	if (oldWrapper) {
		oldWrapper.remove();
	}
	const wrapper = document.createElement("div");
	wrapper.style.height = "100%";
	wrapper.style.width = "100%";
	wrapper.setAttribute("id", "basic_display");
	wrapper.setAttribute("tabindex", "0");
	document.body.appendChild(wrapper);

	function createDisplay({
		rows = 50,
		columns = 50,
		borderWidth = 1,
		borderColor = "black",
		defaultBg = "white",
	} = {}) {
		while (wrapper.firstChild) {
			wrapper.removeChild(wrapper.firstChild);
		}

		return new Display({
			wrapper,
			rows,
			columns,
			defaultBg,
			borderWidth,
			borderColor,
		});
	}

	const cnsle = {
		write: (s) => {
			ipcRenderer.send("output", s);
		},
		clear: () => {
			ipcRenderer.send("clear");
		},
		input: (callback) => {
			ipcRenderer.send("input");
			ipcRenderer.once("write", (event, input) => {
				console.log(input);
				callback(input.replace(/\n$/, ""));
			});
		},
	};

	basic = new Basic({
		console: cnsle,
		createDisplay,
		sound,
		// debugLevel: 9999,
		constants: {
			LEVEL: 1,
			PI: Math.PI,
		},
	});

	// Focus after run. Added delay to make sure everything is rendered
	// and program is running; janky but no good hooks right now.
	setTimeout(() => {
		wrapper.focus();
	}, 100);

	basic
		.run(code)
		.then(() => {
			ipcRenderer.send("result", { data: "" });
		})
		.catch((e) => {
			ipcRenderer.send("result", { error: e.toString() });
		});
});

document.addEventListener(
	"DOMContentLoaded",
	function () {
		ipcRenderer.send("ready");
	},
	false
);
