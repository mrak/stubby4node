'use strict';
/* eslint-disable no-console */

function stripper(args) {
  var key, value;
  for (key in args) {
    if (!args.hasOwnProperty(key)) { continue; }

    value = args[key];
    args[key] = value.replace(/\u001b\[(\d+;?)+m/g, '');
  }
  return args;
}

function colorsafe(console) {
  if (process.stdout.isTTY) { return true; }

  console.raw = {};

  ['log', 'warn', 'info', 'error'].forEach(function (fn) {
    console.raw[fn] = console[fn];
    console[fn] = function () { console.raw[fn].apply(console, stripper(arguments)); };
  });

  return false;
}

module.exports = colorsafe;
