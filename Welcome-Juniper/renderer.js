// File: renderer.js
import { Terminal } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';
import "xterm/css/xterm.css";

const term = new Terminal({
  cursorBlink: true,
  fontFamily: 'monospace',
  theme: {
    background: '#1e1e1e',
    foreground: '#ffffff'
  }
});

const fitAddon = new FitAddon();
term.loadAddon(fitAddon);

window.addEventListener('DOMContentLoaded', () => {
  const terminalContainer = document.getElementById('terminal');
  term.open(terminalContainer);
  fitAddon.fit();
  
  // Display a welcome message
  term.writeln("\x1b[1;32mWelcome to Copilot Shell\x1b[0m");
  term.prompt = () => {
    term.write("\x1b[1;34m$ \x1b[0m");
  };
  term.prompt();

  // Capture input and send to backend
  term.onData(data => {
    window.electronAPI.sendInput(data);
  });

  // Receive output from backend
  window.electronAPI.onOutput((_event, data) => {
    term.write(data);
  });
});
