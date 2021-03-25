'use strict';
/* eslint-disable no-console */

function stripper (args) {
  let key, value;
  for (key in args) {
    if (!Object.prototype.hasOwnProperty.call(args, key)) { continue; }

    value = args[key];
    args[key] = value.replace(/\u001b\[(\d+;?)+m/g, ''); /* eslint-disable-line */
  }
  return args;
}

function colorsafe (console) {
  if (process.stdout.isTTY) { return true; }

  console.raw = {};

  ['log', 'warn', 'info', 'error'].forEach(function (fn) {
    console.raw[fn] = console[fn];
    console[fn] = function () { console.raw[fn].apply(console, stripper(arguments)); };
  });

  return false;
}

module.exports = colorsafe;
