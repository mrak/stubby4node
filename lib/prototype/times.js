'use strict';
/* eslint-disable no-extend-native */

function noop() {}

Object.defineProperty(Number.prototype, 'times', {
  configurable: true,
  value: function (fn) {
    var i;

    if (fn == null) { fn = noop; }
    if (this <= 0) { return this; }

    for (i = 1; i <= this; i++) { fn(); }

    return parseFloat(this);
  }
});

Object.defineProperty(String.prototype, 'times', {
  configurable: true,
  value: function (num) {
    var i;
    var result = '';
    var self = this;

    if (num == null) { num = 1; }
    if (num < 1) { return ''; }

    for (i = 1; i <= num; i++) { result += self; }

    return result;
  }
});

module.exports = function (left, right) {
  if (typeof left !== 'number') { return null; }

  if (typeof right === 'function') {
    return left.times(right);
  }

  if (typeof right === 'string') {
    return right.times(left);
  }
};
