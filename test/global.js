'use strict';

const sinon = require('sinon');
const assert = require('assert');

if (!assert.deepStrictEqual) {
  assert.deepStrictEqual = assert.deepEqual; /* eslint-disable-line */
}

beforeEach(function () { this.sandbox = sinon.createSandbox(); });

afterEach(function () { this.sandbox.restore(); });
