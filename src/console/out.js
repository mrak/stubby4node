'use strict';
/* eslint-disable no-console */

var BOLD = '\x1B[1m';
var BLACK = '\x1B[30m';
var BLUE = '\x1B[34m';
var CYAN = '\x1B[36m';
var GREEN = '\x1B[32m';
var MAGENTA = '\x1B[35m';
var RED = '\x1B[31m';
var YELLOW = '\x1B[33m';
var RESET = '\x1B[0m';

var out = {
  quiet: false,
  debugStubs: false,
  debugHeader: function (msg) {
    if (!this.debugStubs) { return; }
    console.log('----- ' + msg.toUpperCase() + ' ------');
  },
  debug: function (msg, header) {
    if (!this.debugStubs) { return; }
    if (header !== undefined) { console.log('--- ' + header.toUpperCase() + ' ---'); }
    console.log(msg);
  },
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
