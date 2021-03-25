'use strict';
/* eslint-disable no-console */

const BOLD = '\x1B[1m';
const BLACK = '\x1B[30m';
const BLUE = '\x1B[34m';
const CYAN = '\x1B[36m';
const GREEN = '\x1B[32m';
const MAGENTA = '\x1B[35m';
const RED = '\x1B[31m';
const YELLOW = '\x1B[33m';
const RESET = '\x1B[0m';

const out = {
  quiet: false,
  log: function (msg) {
    if (this.quiet) { return; }
    console.log(msg);
  },
  status: function (msg) {
    if (this.quiet) { return; }
    console.log(BOLD + BLACK + msg + RESET);
  },
  dump: function (data) {
    if (this.quiet) { return; }
    console.dir(data);
  },
  info: function (msg) {
    if (this.quiet) { return; }
    console.info(BLUE + msg + RESET);
  },
  ok: function (msg) {
    if (this.quiet) { return; }
    console.log(GREEN + msg + RESET);
  },
  error: function (msg) {
    if (this.quiet) { return; }
    console.error(RED + msg + RESET);
  },
  warn: function (msg) {
    if (this.quiet) { return; }
    console.warn(YELLOW + msg + RESET);
  },
  incoming: function (msg) {
    if (this.quiet) { return; }
    console.log(CYAN + msg + RESET);
  },
  notice: function (msg) {
    if (this.quiet) { return; }
    console.log(MAGENTA + msg + RESET);
  },
  trace: function () {
    if (this.quiet) { return; }
    console.log(RED);
    console.trace();
    console.log(RESET);
  }
};

require('./colorsafe')(out);

module.exports = out;
