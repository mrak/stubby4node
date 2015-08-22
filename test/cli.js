'use strict';

var assert = require('assert');

describe('CLI', function () {
  var out, sut;
  sut = null;
  out = null;
  beforeEach(function () {
    sut = require('../src/console/cli');
    out = require('../src/console/out');
    this.sandbox.stub(process, 'exit');
    return this.sandbox.stub(out, 'log');
  });
  afterEach(function () {
    process.exit.restore();
    return out.log.restore();
  });
  describe('version', function () {
    return it('should return the version of stubby in package.json', function () {
      var expected;
      expected = require('../package.json').version;
      sut.version(true);
      return assert(out.log.calledWith(expected));
    });
  });
  describe('help', function () {
    return it('should return help text', function () {
      sut.help(true);
      return assert(out.log.calledOnce);
    });
  });
  describe('getArgs', function () {
    describe('-a, --admin', function () {
      it('should return default if no flag provided', function () {
        var actual, expected;
        expected = 8889;
        actual = sut.getArgs([]);
        return assert(actual.admin === expected);
      });
      it('should return supplied value when provided', function () {
        var actual, expected;
        expected = '81';
        actual = sut.getArgs(['-a', expected]);
        return assert(actual.admin === expected);
      });
      return it('should return supplied value when provided with full flag', function () {
        var actual, expected;
        expected = '81';
        actual = sut.getArgs(['--admin', expected]);
        return assert(actual.admin === expected);
      });
    });
    describe('-s, --stubs', function () {
      it('should return default if no flag provided', function () {
        var actual, expected;
        expected = 8882;
        actual = sut.getArgs([]);
        return assert(actual.stubs === expected);
      });
      it('should return supplied value when provided', function () {
        var actual, expected;
        expected = '80';
        actual = sut.getArgs(['-s', expected]);
        return assert(actual.stubs === expected);
      });
      return it('should return supplied value when provided with full flag', function () {
        var actual, expected;
        expected = '80';
        actual = sut.getArgs(['--stubs', expected]);
        return assert(actual.stubs === expected);
      });
    });
    describe('-t, --tls', function () {
      it('should return default if no flag provided', function () {
        var actual, expected;
        expected = 7443;
        actual = sut.getArgs([]);
        return assert(actual.tls === expected);
      });
      it('should return supplied value when provided', function () {
        var actual, expected;
        expected = '443';
        actual = sut.getArgs(['-t', expected]);
        return assert(actual.tls === expected);
      });
      return it('should return supplied value when provided with full flag', function () {
        var actual, expected;
        expected = '443';
        actual = sut.getArgs(['--tls', expected]);
        return assert(actual.tls === expected);
      });
    });
    describe('-l, --location', function () {
      it('should return default if no flag provided', function () {
        var actual, expected;
        expected = '0.0.0.0';
        actual = sut.getArgs([]);
        return assert(actual.location === expected);
      });
      it('should return supplied value when provided', function () {
        var actual, expected;
        expected = 'stubby.com';
        actual = sut.getArgs(['-l', expected]);
        return assert(actual.location === expected);
      });
      return it('should return supplied value when provided with full flag', function () {
        var actual, expected;
        expected = 'stubby.com';
        actual = sut.getArgs(['--location', expected]);
        return assert(actual.location === expected);
      });
    });
    describe('-v, --version', function () {
      it('should exit the process', function () {
        sut.getArgs(['--version']);
        return assert(process.exit.calledOnce);
      });
      return it('should print out version info', function () {
        var version;
        version = require('../package.json').version;
        sut.getArgs(['-v']);
        return assert(out.log.calledWith(version));
      });
    });
    return describe('-h, --help', function () {
      it('should exit the process', function () {
        sut.getArgs(['--help']);
        return assert(process.exit.calledOnce);
      });
      return it('should print out help text', function () {
        sut.help();
        sut.getArgs(['-h']);

        assert(out.log.calledOnce);
      });
    });
  });
  describe('data', function () {
    var expected;
    expected = [{
      request: {
        url: '/testput',
        method: 'PUT',
        post: 'test data'
      },
      response: {
        headers: {
          'content-type': 'text/plain'
        },
        status: 404,
        latency: 2000,
        body: 'test response'
      }
    }, {
      request: {
        url: '/testdelete',
        method: 'DELETE',
        post: null
      },
      response: {
        headers: {
          'content-type': 'text/plain'
        },
        status: 204,
        body: null
      }
    }];
    it('should be about to parse json file with array', function () {
      var actual;
      actual = sut.getArgs(['-d', 'test/data/cli.getData.json']);
      return assert.deepEqual(actual.data, expected);
    });
    return it('should be about to parse yaml file with array', function () {
      var actual;
      actual = sut.getArgs(['-d', 'test/data/cli.getData.yaml']);
      return assert.deepEqual(actual.data, expected);
    });
  });
  describe('key', function () {
    return it('should return contents of file', function () {
      var actual, expected;
      expected = 'some generated key';
      actual = sut.key('test/data/cli.getKey.pem');
      return assert(actual === expected);
    });
  });
  describe('cert', function () {
    var expected;
    expected = 'some generated certificate';
    return it('should return contents of file', function () {
      var actual;
      actual = sut.cert('test/data/cli.getCert.pem');
      return assert(actual === expected);
    });
  });
  describe('pfx', function () {
    return it('should return contents of file', function () {
      var actual, expected;
      expected = 'some generated pfx';
      actual = sut.pfx('test/data/cli.getPfx.pfx');
      return assert(actual === expected);
    });
  });
  return describe('getArgs', function () {
    return it('should gather all arguments', function () {
      var actual, expected, filename;
      filename = 'file.txt';
      expected = {
        data: 'a file',
        stubs: '88',
        admin: '90',
        location: 'stubby.com',
        key: 'a key',
        cert: 'a certificate',
        pfx: 'a pfx',
        tls: '443',
        mute: true,
        watch: filename,
        datadir: process.cwd(),
        help: null,
        version: (require('../package.json')).version
      };
      this.sandbox.stub(sut, 'data').returns(expected.data);
      this.sandbox.stub(sut, 'key').returns(expected.key);
      this.sandbox.stub(sut, 'cert').returns(expected.cert);
      this.sandbox.stub(sut, 'pfx').returns(expected.pfx);
      actual = sut.getArgs(['-s', expected.stubs, '-a', expected.admin, '-d', filename, '-l', expected.location, '-k', 'mocked', '-c', 'mocked', '-p', 'mocked', '-t', expected.tls, '-m', '-w']);
      assert.deepEqual(actual, expected);
      sut.data.restore();
      sut.key.restore();
      sut.cert.restore();
      return sut.pfx.restore();
    });
  });
});
