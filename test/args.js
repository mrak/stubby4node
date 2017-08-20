'use strict';

var assert = require('assert');
var sut = require('../src/console/args');

describe('args', function () {
  describe('parse', function () {
    describe('flags', function () {
      it('should parse a flag without parameters', function () {
        var options = [{
          name: 'flag',
          flag: 'f'
        }];

        var result = sut.parse(options, ['-f']);

        assert.strictEqual(result.flag, true);
      });

      it('should parse two flags without parameters', function () {
        var options = [{
          name: 'one',
          flag: 'o'
        }, {
          name: 'two',
          flag: 't'
        }];

        var result = sut.parse(options, ['-ot']);

        assert.strictEqual(result.one, true);
        assert.strictEqual(result.two, true);
      });

      it('should default to false for flag without parameters', function () {
        var options = [{
          name: 'flag',
          flag: 'f'
        }];

        var result = sut.parse(options, []);

        assert.strictEqual(result.flag, false);
      });

      it('should parse a flag with parameters', function () {
        var expected = 'a_value';
        var options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything'
        }];

        var result = sut.parse(options, ['-f', expected]);

        assert.strictEqual(result.flag, expected);
      });

      it('should parse two flags with parameters', function () {
        var options = [{
          name: 'one',
          flag: 'o',
          param: 'named'
        }, {
          name: 'two',
          flag: 't',
          param: 'named'
        }];

        var result = sut.parse(options, ['-o', 'one', '-t', 'two']);

        assert.strictEqual(result.one, 'one');
        assert.strictEqual(result.two, 'two');
      });

      it('should be default if flag not supplied', function () {
        var expected = 'a_value';
        var options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];

        var result = sut.parse(options, []);

        assert.strictEqual(result.flag, expected);
      });

      it('should be default if flag parameter not supplied', function () {
        var expected = 'a_value';
        var options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];

        var result = sut.parse(options, ['-f']);

        assert.strictEqual(result.flag, expected);
      });

      it('should be default if flag parameter skipped', function () {
        var expected = 'a_value';
        var options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];

        var result = sut.parse(options, ['-f', '-z']);

        assert.strictEqual(result.flag, expected);
      });

      it('should parse a flag with parameters combined with a flag without parameters', function () {
        var options = [{
          name: 'one',
          flag: 'o',
          param: 'named'
        }, {
          name: 'two',
          flag: 't'
        }];

        var result = sut.parse(options, ['-ot', 'one']);

        assert.strictEqual(result.one, 'one');
        assert.strictEqual(result.two, true);
      });
    });

    describe('names', function () {
      it('should parse a name without parameters', function () {
        var options = [{
          name: 'flag',
          flag: 'f'
        }];

        var result = sut.parse(options, ['--flag']);

        assert.strictEqual(result.flag, true);
      });

      it('should parse two names without parameters', function () {
        var options = [{
          name: 'one',
          flag: 'o'
        }, {
          name: 'two',
          flag: 't'
        }];

        var result = sut.parse(options, ['--one', '--two']);

        assert.strictEqual(result.one, true);
        assert.strictEqual(result.two, true);
      });

      it('should default to false for name without parameters', function () {
        var options = [{
          name: 'flag',
          flag: 'f'
        }];

        var result = sut.parse(options, []);

        assert.strictEqual(result.flag, false);
      });

      it('should parse a name with parameters', function () {
        var expected = 'a_value';
        var options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything'
        }];

        var result = sut.parse(options, ['--flag', expected]);

        assert.strictEqual(result.flag, expected);
      });

      it('should parse two names with parameters', function () {
        var options = [{
          name: 'one',
          flag: 'o',
          param: 'named'
        }, {
          name: 'two',
          flag: 't',
          param: 'named'
        }];

        var result = sut.parse(options, ['--one', 'one', '--two', 'two']);

        assert.strictEqual(result.one, 'one');
        assert.strictEqual(result.two, 'two');
      });

      it('should be default if name not supplied', function () {
        var expected = 'a_value';
        var options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];

        var result = sut.parse(options, []);

        assert.strictEqual(result.flag, expected);
      });

      it('should be default if name parameter not supplied', function () {
        var expected = 'a_value';
        var options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];

        var result = sut.parse(options, ['--flag']);

        assert.strictEqual(result.flag, expected);
      });

      it('should be default if name parameter skipped', function () {
        var expected = 'a_value';
        var options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];

        var result = sut.parse(options, ['--flag', '--another-flag']);

        assert.strictEqual(result.flag, expected);
      });
    });
  });
});
