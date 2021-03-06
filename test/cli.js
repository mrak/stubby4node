'use strict';

const assert = require('assert');
const sut = require('../src/console/cli');
const out = require('../src/console/out');

describe('CLI', function () {
  beforeEach(function () {
    this.sandbox.stub(process, 'exit');
    this.sandbox.stub(out, 'log');
  });

  describe('version', function () {
    it('should return the version of stubby in package.json', function () {
      const expected = require('../package.json').version;

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
        const expected = 8889;

        const actual = sut.getArgs([]);

        assert.strictEqual(actual.admin, expected);
      });

      it('should return supplied value when provided', function () {
        const expected = '81';

        const actual = sut.getArgs(['-a', expected]);

        assert.strictEqual(actual.admin, expected);
      });

      it('should return supplied value when provided with full flag', function () {
        const expected = '81';
        const actual = sut.getArgs(['--admin', expected]);
        assert.strictEqual(actual.admin, expected);
      });
    });

    describe('-s, --stubs', function () {
      it('should return default if no flag provided', function () {
        const expected = 8882;

        const actual = sut.getArgs([]);

        assert.strictEqual(actual.stubs, expected);
      });

      it('should return supplied value when provided', function () {
        const expected = '80';

        const actual = sut.getArgs(['-s', expected]);

        assert.strictEqual(actual.stubs, expected);
      });

      it('should return supplied value when provided with full flag', function () {
        const expected = '80';
        const actual = sut.getArgs(['--stubs', expected]);
        assert.strictEqual(actual.stubs, expected);
      });
    });

    describe('-t, --tls', function () {
      it('should return default if no flag provided', function () {
        const expected = 7443;

        const actual = sut.getArgs([]);

        assert.strictEqual(actual.tls, expected);
      });

      it('should return supplied value when provided', function () {
        const expected = '443';

        const actual = sut.getArgs(['-t', expected]);

        assert.strictEqual(actual.tls, expected);
      });

      it('should return supplied value when provided with full flag', function () {
        const expected = '443';

        const actual = sut.getArgs(['--tls', expected]);

        assert.strictEqual(actual.tls, expected);
      });
    });

    describe('-l, --location', function () {
      it('should return default if no flag provided', function () {
        const expected = '0.0.0.0';

        const actual = sut.getArgs([]);

        assert.strictEqual(actual.location, expected);
      });

      it('should return supplied value when provided', function () {
        const expected = 'stubby.com';

        const actual = sut.getArgs(['-l', expected]);

        assert.strictEqual(actual.location, expected);
      });

      it('should return supplied value when provided with full flag', function () {
        const expected = 'stubby.com';

        const actual = sut.getArgs(['--location', expected]);

        assert.strictEqual(actual.location, expected);
      });
    });

    describe('-v, --version', function () {
      it('should exit the process', function () {
        sut.getArgs(['--version']);

        assert(process.exit.calledOnce);
      });
      it('should print out version info', function () {
        const version = require('../package.json').version;

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
    const expected = [{
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
      const actual = sut.getArgs(['-d', 'test/data/cli.getData.json']);
      assert.deepStrictEqual(actual.data, expected);
    });

    it('should be about to parse yaml file with array', function () {
      const actual = sut.getArgs(['-d', 'test/data/cli.getData.yaml']);
      assert.deepStrictEqual(actual.data, expected);
    });
  });

  describe('key', function () {
    it('should return contents of file', function () {
      const expected = 'some generated key';

      const actual = sut.key('test/data/cli.getKey.pem');

      assert.strictEqual(actual, expected);
    });
  });

  describe('cert', function () {
    const expected = 'some generated certificate';

    it('should return contents of file', function () {
      const actual = sut.cert('test/data/cli.getCert.pem');

      assert.strictEqual(actual, expected);
    });
  });

  describe('pfx', function () {
    it('should return contents of file', function () {
      const expected = 'some generated pfx';

      const actual = sut.pfx('test/data/cli.getPfx.pfx');

      assert.strictEqual(actual, expected);
    });
  });

  describe('-H, --case-sensitive-headers', function () {
    it('should return default if no flag provided', function () {
      const expected = false;
      const actual = sut.getArgs([]);
      assert.strictEqual(actual['case-sensitive-headers'], expected);
    });

    it('should return supplied value when provided', function () {
      const expected = true;
      const actual = sut.getArgs(['-H', expected]);
      assert.strictEqual(actual['case-sensitive-headers'], expected);
    });

    it('should return supplied value when provided with full flag', function () {
      const expected = true;
      const actual = sut.getArgs(['--case-sensitive-headers', expected]);
      assert.strictEqual(actual['case-sensitive-headers'], expected);
    });
  });

  describe('getArgs', function () {
    it('should gather all arguments', function () {
      const filename = 'file.txt';
      const expected = {
        data: 'a file',
        stubs: '88',
        admin: '90',
        location: 'stubby.com',
        key: 'a key',
        cert: 'a certificate',
        pfx: 'a pfx',
        tls: '443',
        quiet: true,
        watch: filename,
        datadir: process.cwd(),
        'case-sensitive-headers': true,
        help: undefined, // eslint-disable-line no-undefined
        version: (require('../package.json')).version
      };
      this.sandbox.stub(sut, 'data').returns(expected.data);
      this.sandbox.stub(sut, 'key').returns(expected.key);
      this.sandbox.stub(sut, 'cert').returns(expected.cert);
      this.sandbox.stub(sut, 'pfx').returns(expected.pfx);

      const actual = sut.getArgs(['-s', expected.stubs, '-a', expected.admin, '-d', filename, '-l', expected.location, '-k', 'mocked', '-c', 'mocked', '-p', 'mocked', '-t', expected.tls, '-q', '-w', '-H']);

      assert.deepStrictEqual(actual, expected);
    });
  });
});
