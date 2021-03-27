'use strict';
const assert = require('assert');

module.exports = function waitsFor (fn, message, range, finish, time) {
  const min = range[0] != null ? range[0] : 0;
  const max = range[1] != null ? range[1] : range;

  if (time == null) { time = process.hrtime(); }

  const temp = time == null ? process.hrtime() : process.hrtime(time);
  const seconds = temp[0];
  const nanoseconds = temp[1];
  const elapsed = seconds * 1000 + nanoseconds / 1000000;

  assert(elapsed < max, 'Timed out waiting ' + max + 'ms for ' + message);

  if (fn()) {
    assert(elapsed > min, 'Condition succeeded before ' + min + 'ms were up');
    return finish();
  }

  setTimeout(function () {
    waitsFor(fn, message, range, finish, time);
  }, 1);
};
