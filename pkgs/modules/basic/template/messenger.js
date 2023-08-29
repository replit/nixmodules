const { EventEmitter } = require('events');
const { ipcRenderer } = require('electron');

const Messenger = new EventEmitter();

function messengerEmit(event, data) {
	return Messenger.emit(event, data);
}

ipcRenderer.on('evaluate', data => {
		messengerEmit('evaluate', data)
});

let iframe = false;
if (typeof window === 'object' && window && window.parent) {
	iframe = true;
	Messenger.global = window;
	window.parent.stuffOn('evaluate', options => {
		messengerEmit('evaluate', options);
	});

	window.parent.stuffOn('runProject', options => {
		messengerEmit('runProject', options);
	});

	window.parent.stuffOn('write', str => {
		messengerEmit('write', str);
	});

	window.parent.stuffOn('checkLine', command => {
		if (!Messenger.listeners('checkLine').length) {
			// No one bothered to listen on this event, just say no.
			Messenger.checkLineEnd(false);
		} else {
			messengerEmit('checkLine', command);
		}
	});

	window.parent.stuffOn(
		'runSingleUnitTests',
		({ code, url, suiteCode, infiniteLoopProtection }) => {
			messengerEmit('runSingleUnitTests', {
				code,
				url,
				suiteCode,
				infiniteLoopProtection,
			});
		},
	);

	window.parent.stuffOn(
		'runUnitTests',
		({ files, suiteCode, infiniteLoopProtection }) => {
			messengerEmit('runUnitTests', {
				files,
				suiteCode,
				infiniteLoopProtection,
			});
		},
	);

	window.parent.stuffOn('reset', () => {
		messengerEmit('reset');
	});

	window.parent.stuffOn('refresh', () => {
		messengerEmit('refresh');
	});

	window.parent.stuffOn('stop', () => {
		messengerEmit('stop');
	});

	window.parent.stuffOn('overridePrompt', () => {
		messengerEmit('overridePrompt');
	});

	window.parent.stuffOn('loadLibrary', name => {
		Messenger.emit('loadLibrary', name);
	});
} else {
	Messenger.global = self;
	// Some scripts reference window directly.
	Messenger.global.window = self;
	self.addEventListener('message', e => {
		if (!e.data) {
			return;
		}

		// Note that runProject is not implemented here.
		switch (e.data.type) {
			case 'evaluate':
				messengerEmit(e.data.type, {
					code: e.data.data,
				});
				break;
			case 'write':
			case 'runSingleUnitTests':
			case 'runUnitTests':
				messengerEmit(e.data.type, e.data.data);
				break;
			case 'checkLine':
				if (!Messenger.listeners('checkLine').length) {
					// No one bothered to listen on this event, just say no.
					Messenger.checkLineEnd(false);
				} else {
					messengerEmit('checkLine', e.data.data);
				}
				break;
			case 'reset':
				messengerEmit('reset');
				break;
			default:
				throw new Error(`Unkown message type: ${e.data.type}`);
		}
	});
}

// Support sync throtelling and async debouncing.
// So that we don't hold back the output from long running
// sync programs. And that we don't hold back forever on
// things that we can flush asnyncly.
let buffer = '';
let bufferTime;
let timer;

function flush() {
	bufferTime = null;
	clearTimeout(timer);
	timer = null;
	if (iframe) {
		window.parent.stuffEmit('output', buffer);
	} else {
		self.postMessage({
			type: 'output',
			data: buffer,
		});
	}
	buffer = '';
}

Messenger.output = function(output) {
	buffer += output;
	clearTimeout(timer);
	timer = setTimeout(flush, 50);

	if (!bufferTime) {
		bufferTime = Date.now();
		return;
	}

	if (Date.now() - bufferTime > 50) {
		flush();
	}
};

Messenger.unbufferedOutput = function(output) {
	if (iframe) {
		window.parent.stuffEmit('output', output);
	} else {
		self.postMessage({
			type: 'output',
			data: output,
		});
	}
};

Messenger.output.clear = function() {
	flush();
	if (iframe) {
		window.parent.stuffEmit('clearConsole');
	} else {
		self.postMessage({
			type: 'clearConsole',
		});
	}
};

Messenger.result = function(message) {
	flush();
	if (iframe) {
		window.parent.stuffEmit('result', message);
	} else {
		self.postMessage({
			type: 'result',
			...message,
		});
	}
};

Messenger.stderr = function(errStr) {
	if (iframe) {
		window.parent.stuffEmit('stderr', errStr);
	} else {
		self.postMessage({
			type: 'stderr',
			errStr,
		});
	}
};

Messenger.error = function(err) {
	Messenger.reportError(err);

	if (iframe) {
		window.parent.stuffEmit('error', err.message);
	} else {
		self.postMessage({
			type: 'error',
			data: err.message,
		});
	}

	console.error(err.stack || err.message); // eslint-disable-line
};

// This is only meant to say that we're waiting for input in
// case the UI wants to react.
Messenger.inputEvent = () => {
	if (iframe) {
		window.parent.stuffEmit('input');
	} else {
		self.postMessage({
			type: 'error',
		});
	}
};

Messenger.ready = function() {
	if (iframe) {
		window.parent.stuffEmit('ready');
	} else {
		self.postMessage({ type: 'ready' });
	}
};

Messenger.resetReady = function() {
	if (iframe) {
		window.parent.stuffEmit('resetReady');
	} else {
		self.postMessage({ type: 'resetReady' });
	}
};

Messenger.warn = function(msg) {
	if (iframe) {
		window.parent.stuffEmit('warn', msg);
	} else {
		self.postMessage({
			type: 'warn',
			data: msg,
		});
	}
};

Messenger.checkLineEnd = function(result) {
	if (iframe) {
		window.parent.stuffEmit('checkLine', result);
	} else {
		self.postMessage({
			type: 'checkLine',
			data: result,
		});
	}
};

Messenger.loadedLibrary = function(name) {
	if (iframe) {
		window.parent.stuffEmit('loadedLibrary', name);
	}
};

Messenger.loadFailedLibrary = function(name, msg) {
	if (iframe) {
		window.parent.stuffEmit('loadFailedLibrary', name, msg);
	}
};

Messenger.reportError = e => {
		console.log(e);
};

Messenger.track = (eventName, props) => {
	window.parent.stuffEmit('track', { eventName, props });
};

if (iframe) {
	const css = `
		body {
			border: none;
			padding: 0;
			margin: 0;
			height: 100%;
			width: 100%;
		}
		#skulpt_target {
			height: 100%;
			width: 100%;
			overflow: scroll;
			outline: none;
			box-sizing: border-box;
		}
		#skulpt_target:focus {
			border: 1px solid #6d7ebd;
		}
		#basic_display {
			display: flex;
			justify-content: center;
			align-items: center;			
		}
		#basic_display:focus canvas {
			box-shadow: 0px 0px 13px 6px rgba(0,0,0,0.42);
		}
	`;

	const style = document.createElement('style');
	style.type = 'text/css';

	if (style.styleSheet) {
		style.styleSheet.cssText = css;
	} else {
		style.appendChild(document.createTextNode(css));
	}

	document.head.appendChild(style);
}

Messenger.isIframe = iframe;

module.exports = Messenger;
