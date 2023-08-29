const { contextBridge, ipcRenderer } = require("electron");

console.log(ipcRenderer);

contextBridge.exposeInMainWorld("ipcRenderer", ipcRenderer);
