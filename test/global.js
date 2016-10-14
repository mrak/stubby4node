'use strict';

var sinon = require('sinon');
var assert = require('assert');

if (!assert.deepStrictEqual) {
  assert.deepStrictEqual = assert.deepEqual;
}

beforeEach(function () {
  this.sandbox = sinon.sandbox.create();
});

afterEach(function () {
  this.sandbox.restore();
});
