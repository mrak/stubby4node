'use strict';

module.exports = function clone (x) {
  return JSON.parse(JSON.stringify(x));
};
