const fs = require('fs');
const tail = require('tail').Tail;
const t = new tail("/var/log/syslog");
import pty from 'node-pty'; 

t.on("line", function(data) {
  console.log("LOG:", data);
});
