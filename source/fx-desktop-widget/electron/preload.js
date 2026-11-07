const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("fxWindow", {
  minimize: () => ipcRenderer.send("window:minimize"),
  close: () => ipcRenderer.send("window:close")
});
