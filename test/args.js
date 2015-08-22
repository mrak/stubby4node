'use strict';

var assert = require('assert');
var sut = null;

describe('args', function () {
  beforeEach(function () {
    sut = require('../src/console/args');
  });
  return describe('parse', function () {
    describe('flags', function () {
      it('should parse a flag without parameters', function () {
        var options, result;
        options = [{
          name: 'flag',
          flag: 'f'
        }];
        result = sut.parse(options, ['-f']);
        return assert(result.flag === true);
      });
      it('should parse two flags without parameters', function () {
        var options, result;
        options = [{
          name: 'one',
          flag: 'o'
        }, {
          name: 'two',
          flag: 't'
        }];
        result = sut.parse(options, ['-ot']);
        assert(result.one === true);
        return assert(result.two === true);
      });
      it('should default to false for flag without parameters', function () {
        var options, result;
        options = [{
          name: 'flag',
          flag: 'f'
        }];
        result = sut.parse(options, []);
        return assert(result.flag === false);
      });
      it('should parse a flag with parameters', function () {
        var expected, options, result;
        expected = 'a_value';
        options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything'
        }];
        result = sut.parse(options, ['-f', expected]);
        return assert(result.flag === expected);
      });
      it('should parse two flags with parameters', function () {
        var options, result;
        options = [{
          name: 'one',
          flag: 'o',
          param: 'named'
        }, {
          name: 'two',
          flag: 't',
          param: 'named'
        }];
        result = sut.parse(options, ['-o', 'one', '-t', 'two']);
        assert(result.one === 'one');
        return assert(result.two === 'two');
      });
      it('should be default if flag not supplied', function () {
        var expected, options, result;
        expected = 'a_value';
        options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];
        result = sut.parse(options, []);
        return assert(result.flag === expected);
      });
      it('should be default if flag parameter not supplied', function () {
        var expected, options, result;
        expected = 'a_value';
        options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];
        result = sut.parse(options, ['-f']);
        return assert(result.flag === expected);
      });
      it('should be default if flag parameter skipped', function () {
        var expected, options, result;
        expected = 'a_value';
        options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];
        result = sut.parse(options, ['-f', '-z']);
        return assert(result.flag === expected);
      });
      return it('should parse a flag with parameters combined with a flag without parameters', function () {
        var options, result;
        options = [{
          name: 'one',
          flag: 'o',
          param: 'named'
        }, {
          name: 'two',
          flag: 't'
        }];
        result = sut.parse(options, ['-ot', 'one']);
        assert(result.one === 'one');
        return assert(result.two === true);
      });
    });
    return describe('names', function () {
      it('should parse a name without parameters', function () {
        var options, result;
        options = [{
          name: 'flag',
          flag: 'f'
        }];
        result = sut.parse(options, ['--flag']);
        return assert(result.flag === true);
      });
      it('should parse two names without parameters', function () {
        var options, result;
        options = [{
          name: 'one',
          flag: 'o'
        }, {
          name: 'two',
          flag: 't'
        }];
        result = sut.parse(options, ['--one', '--two']);
        assert(result.one === true);
        return assert(result.two === true);
      });
      it('should default to false for name without parameters', function () {
        var options, result;
        options = [{
          name: 'flag',
          flag: 'f'
        }];
        result = sut.parse(options, []);
        return assert(result.flag === false);
      });
      it('should parse a name with parameters', function () {
        var expected, options, result;
        expected = 'a_value';
        options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything'
        }];
        result = sut.parse(options, ['--flag', expected]);
        return assert(result.flag === expected);
      });
      it('should parse two names with parameters', function () {
        var options, result;
        options = [{
          name: 'one',
          flag: 'o',
          param: 'named'
        }, {
          name: 'two',
          flag: 't',
          param: 'named'
        }];
        result = sut.parse(options, ['--one', 'one', '--two', 'two']);
        assert(result.one === 'one');
        return assert(result.two === 'two');
      });
      it('should be default if name not supplied', function () {
        var expected, options, result;
        expected = 'a_value';
        options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];
        result = sut.parse(options, []);
        return assert(result.flag === expected);
      });
      it('should be default if name parameter not supplied', function () {
        var expected, options, result;
        expected = 'a_value';
        options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];
        result = sut.parse(options, ['--flag']);
        return assert(result.flag === expected);
      });
      return it('should be default if name parameter skipped', function () {
        var expected, options, result;
        expected = 'a_value';
        options = [{
          name: 'flag',
          flag: 'f',
          param: 'anything',
          default: expected
        }];
        result = sut.parse(options, ['--flag', '--another-flag']);
        return assert(result.flag === expected);
      });
    });
  });
});
