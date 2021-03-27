'use strict';

const sut = require('../src/console/prettyprint');
const assert = require('assert');

describe('prettyprint', function () {
  describe('wrap', function () {
    it('should linebreak at word instead of character given tokens', function () {
      const continuationIndent = 0;
      const columns = 25;
      const words = 'one fish, two fish, red fish, blue fish'.split(' ');
      const actual = sut(words, continuationIndent, columns);

      assert.strictEqual(actual, 'one fish, two fish, red\nfish, blue fish');
    });

    it('should indent before subsequent lines', function () {
      const continuationIndent = 5;
      const columns = 25;
      const words = 'one fish, two fish, red fish, blue fish'.split(' ');
      const actual = sut(words, continuationIndent, columns);

      assert.strictEqual(actual, 'one fish, two fish,\n     red fish, blue fish');
    });

    it('should wrap past multiple lines', function () {
      const continuationIndent = 5;
      const columns = 15;
      const words = 'one fish, two fish, red fish, blue fish'.split(' ');
      const actual = sut(words, continuationIndent, columns);

      assert.strictEqual(actual, 'one fish,\n     two fish,\n     red fish,\n     blue fish');
    });
  });
});
