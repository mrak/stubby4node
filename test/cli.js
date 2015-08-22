'use strict';

var assert = require('assert');
var sut = require('../src/console/cli');
var out = require('../src/console/out');

describe('CLI', function () {
  beforeEach(function () {
    this.sandbox.stub(process, 'exit');
    this.sandbox.stub(out, 'log');
  });

  describe('version', function () {
    it('should return the version of stubby in package.json', function () {
      var expected = require('../package.json').version;

      sut.version(true);

      assert(out.log.calledWith(expected));
    });
  });

  describe('help', function () {
    it('should return help text', function () {
      sut.help(true);

      assert(out.log.calledOnce);
    });
  });

  describe('getArgs', function () {
    describe('-a, --admin', function () {
      it('should return default if no flag provided', function () {
        var expected = 8889;

        var actual = sut.getArgs([]);

        assert(actual.admin === expected);
      });

      it('should return supplied value when provided', function () {
        var expected = '81';

        var actual = sut.getArgs(['-a', expected]);

        assert(actual.admin === expected);
      });

      it('should return supplied value when provided with full flag', function () {
        var expected = '81';
        var actual = sut.getArgs(['--admin', expected]);
        assert(actual.admin === expected);
      });
    });

    describe('-s, --stubs', function () {
      it('should return default if no flag provided', function () {
        var expected = 8882;

        var actual = sut.getArgs([]);

        assert(actual.stubs === expected);
      });

      it('should return supplied value when provided', function () {
        var expected = '80';

        var actual = sut.getArgs(['-s', expected]);

        assert(actual.stubs === expected);
      });

      it('should return supplied value when provided with full flag', function () {
        var expected = '80';
        var actual = sut.getArgs(['--stubs', expected]);
        assert(actual.stubs === expected);
      });
    });

    describe('-t, --tls', function () {
      it('should return default if no flag provided', function () {
        var expected = 7443;

        var actual = sut.getArgs([]);

        assert(actual.tls === expected);
      });

      it('should return supplied value when provided', function () {
        var expected = '443';

        var actual = sut.getArgs(['-t', expected]);

        assert(actual.tls === expected);
      });

      it('should return supplied value when provided with full flag', function () {
        var expected = '443';

        var actual = sut.getArgs(['--tls', expected]);

        assert(actual.tls === expected);
      });
    });

    describe('-l, --location', function () {
      it('should return default if no flag provided', function () {
        var expected = '0.0.0.0';

        var actual = sut.getArgs([]);

        assert(actual.location === expected);
      });

      it('should return supplied value when provided', function () {
        var expected = 'stubby.com';

        var actual = sut.getArgs(['-l', expected]);

        assert(actual.location === expected);
      });

      it('should return supplied value when provided with full flag', function () {
        var expected = 'stubby.com';

        var actual = sut.getArgs(['--location', expected]);

        assert(actual.location === expected);
      });
    });

    describe('-v, --version', function () {
      it('should exit the process', function () {
        sut.getArgs(['--version']);

        assert(process.exit.calledOnce);
      });
      it('should print out version info', function () {
        var version = require('../package.json').version;

        sut.getArgs(['-v']);

        assert(out.log.calledWith(version));
      });
    });

    describe('-h, --help', function () {
      it('should exit the process', function () {
        sut.getArgs(['--help']);

        assert(process.exit.calledOnce);
      });

      it('should print out help text', function () {
        sut.help();
        sut.getArgs(['-h']);

        assert(out.log.calledOnce);
      });
    });
  });

  describe('data', function () {
    var expected = [{
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
      var actual = sut.getArgs(['-d', 'test/data/cli.getData.json']);
      assert.deepEqual(actual.data, expected);
    });

    it('should be about to parse yaml file with array', function () {
      var actual = sut.getArgs(['-d', 'test/data/cli.getData.yaml']);
      assert.deepEqual(actual.data, expected);
    });
  });

  describe('key', function () {
    it('should return contents of file', function () {
      var expected = 'some generated key';

      var actual = sut.key('test/data/cli.getKey.pem');

      assert(actual === expected);
    });
  });

  describe('cert', function () {
    var expected = 'some generated certificate';

    it('should return contents of file', function () {
      var actual = sut.cert('test/data/cli.getCert.pem');

      assert(actual === expected);
    });
  });

  describe('pfx', function () {
    it('should return contents of file', function () {
      var expected = 'some generated pfx';

      var actual = sut.pfx('test/data/cli.getPfx.pfx');

      assert(actual === expected);
    });
  });

  describe('getArgs', function () {
    it('should gather all arguments', function () {
      var actual;
      var filename = 'file.txt';
      var expected = {
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
        help: undefined, // eslint-disable-line no-undefined
        version: (require('../package.json')).version
      };
      this.sandbox.stub(sut, 'data').returns(expected.data);
      this.sandbox.stub(sut, 'key').returns(expected.key);
      this.sandbox.stub(sut, 'cert').returns(expected.cert);
      this.sandbox.stub(sut, 'pfx').returns(expected.pfx);

      actual = sut.getArgs(['-s', expected.stubs, '-a', expected.admin, '-d', filename, '-l', expected.location, '-k', 'mocked', '-c', 'mocked', '-p', 'mocked', '-t', expected.tls, '-m', '-w']);

      assert.deepEqual(actual, expected);
    });
  });
});
