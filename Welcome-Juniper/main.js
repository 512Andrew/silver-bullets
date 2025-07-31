const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const pty = require('node-pty');

let mainWindow;
let shell;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 900,
    height: 600,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      sandbox: true
    }
  });

  mainWindow.loadFile('index.html');

  // Create a pseudo-terminal with bash
  shell = pty.spawn('bash', [], {
    name: 'xterm-color',
    cols: 80,
    rows: 24,
    cwd: process.env.HOME,
    env: process.env
  });

  // Send shell output to renderer
  shell.onData(data => {
    mainWindow.webContents.send('terminal-output', data);
  });

  // Receive input from renderer and write to shell
  ipcMain.on('terminal-input', (_event, input) => {
    shell.write(input);
  });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
