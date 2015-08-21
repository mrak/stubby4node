'use strict';

var sut = require('../src/console/prettyprint');
var assert = require('assert');

describe('prettyprint', function () {
  describe('spacing', function () {
    it('should return an empty string if given no parameters', function () {
      var actual = sut.spacing();

      assert(actual === '');
    });

    it('should return five spaces if given 5', function () {
      var actual = sut.spacing(5);

      assert(actual === '     ');
    });

    it('should return empty string if given negative number', function () {
      var actual = sut.spacing(-5);

      assert(actual === '');
    });
  });

  describe('wrap', function () {
    it('should linebreak at word instead of character given tokens', function () {
      var continuationIndent = 0;
      var columns = 25;
      var words = 'one fish, two fish, red fish, blue fish'.split(' ');
      var actual = sut.wrap(words, continuationIndent, columns);

      assert(actual === 'one fish, two fish, red\nfish, blue fish');
    });

    it('should indent before subsequent lines', function () {
      var continuationIndent = 5;
      var columns = 25;
      var words = 'one fish, two fish, red fish, blue fish'.split(' ');
      var actual = sut.wrap(words, continuationIndent, columns);

      assert(actual === 'one fish, two fish,\n     red fish, blue fish');
    });

    it('should wrap past multiple lines', function () {
      var continuationIndent = 5;
      var columns = 15;
      var words = 'one fish, two fish, red fish, blue fish'.split(' ');
      var actual = sut.wrap(words, continuationIndent, columns);

      assert(actual === 'one fish,\n     two fish,\n     red fish,\n     blue fish');
    });
  });
});
