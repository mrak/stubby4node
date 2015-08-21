'use strict';

var assert = require('assert');

module.exports = function waitsFor(fn, message, range, finish, time) {
  if (time == null) { time = process.hrtime(); }

  var min = range[0] != null ? range[0] : 0;
  var max = range[1] != null ? range[1] : range;
  var temp = time == null ? process.hrtime() : process.hrtime(time);
  var seconds = temp[0];
  var nanoseconds = temp[1];
  var elapsed = seconds * 1000 + nanoseconds / 1000000;

  assert(elapsed < max, "Timed out waiting " + max + "ms for " + message);

  if (fn()) {
    assert(elapsed > min, "Condition succeeded before " + min + "ms were up");
    return finish();
  }

  if (setImmediate != null) {
    setImmediate(function() {
      waitsFor(fn, message, range, finish, time);
    });
  } else {
    setTimeout(function() {
      waitsFor(fn, message, range, finish, time);
    }, 5);
  }
};
