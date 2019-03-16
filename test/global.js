'use strict';

var sinon = require('sinon');
var assert = require('assert');

if (!assert.deepStrictEqual) {
  assert.deepStrictEqual = assert.deepEqual; /* eslint-disable-line */
}

beforeEach(function () {
  this.sandbox = sinon.createSandbox();
});

afterEach(function () {
  this.sandbox.restore();
});
