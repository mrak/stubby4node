'use strict';

function noop() {}

Object.defineProperty(Number.prototype, "times", {
  configurable: true,
  value: function (fn) {
    if (fn == null) { fn = noop; }
    if (this <= 0) { return this; }

    for (var i = 1; i <= this; i++) { fn(); }

    return parseFloat(this);
  }
});

Object.defineProperty(String.prototype, "times", {
  configurable: true,
  value: function(num) {
    if (num == null) { num = 1; }
    if (num < 1) { return ''; }

    var result = '';
    for (var i = 1; i <= num; i++) { result += this; }

    return result;
  }
});

module.exports = function(left, right) {
  if (typeof left !== 'number') { return; }

  if (typeof right === 'function') {
    return left.times(right);
  }

  if (typeof right === 'string') {
    return right.times(left);
  }
};
