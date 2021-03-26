'use strict';

const CLI = require('../src/console/cli');
const defaults = CLI.getArgs([]);
const assert = require('assert');
const Stubby = require('../src/main').Stubby;

describe('main', function () {
  let sut, options;

  async function stopStubby () {
    if (sut != null) await sut.stop();
  }

  beforeEach(async () => {
    await stopStubby();
    sut = new Stubby();
  });

  afterEach(stopStubby);

  describe('put', function () {
    it('should throw warning when the contract is violated', async () => {
      sut.endpoints = { update: function () {} };

      await assert.rejects(async () => {
        await sut.put('42', {
          request: {
            url: '/somewhere'
          },
          response: {
            status: 800
          }
        });
      }, {
        message: "The supplied endpoint data couldn't be saved"
      });
    });

    it('should not return warning when the contract is upheld', async () => {
      sut.endpoints = { update: function () {} };

      await sut.put('42', {
        request: {
          url: '/somewhere'
        },
        response: {
          status: 200
        }
      });
    });
  });

  describe('post', function () {
    it('should throw warning when the contract is violated', async () => {
      await assert.rejects(async () => {
        await sut.post({
          request: {
            url: '/somewhere'
          },
          response: {
            status: 800
          }
        });
      }, {
        message: "The supplied endpoint data couldn't be saved"
      });
    });

    it('should not throw warning when the contract is upheld', async () => {
      await sut.post({
        request: {
          url: '/somewhere'
        },
        response: {
          status: 200
        }
      });
    });
  });

  describe('delete', function () {
    it('should call delete all when no id is passed', function (done) {
      sut.endpoints = { deleteAll: done };

      sut.delete();
    });

    it('should call delete when an id is passed', function (done) {
      sut.endpoints = {
        delete: function (id) {
          assert.strictEqual(id, '1');
          done();
        }
      };

      sut.delete('1');
    });
  });

  describe('start', function () {
    beforeEach(function () {
      options = {};
    });

    describe('callback', function () {
      it('should not fail to start a server without options', async () => {
        await sut.start();
      });
    });

    describe('options', function () {
      it('should default stub port to CLI port default', async () => {
        await sut.start(options);
        assert.strictEqual(options.stubs, defaults.stubs);
      });

      it('should default admin port to CLI port default', async () => {
        await sut.start(options);
        assert.strictEqual(options.admin, defaults.admin);
      });

      it('should default location to CLI default', async () => {
        await sut.start(options);
        assert.strictEqual(options.location, defaults.location);
      });

      it('should default data to empty array', async () => {
        await sut.start(options);
        assert(options.data instanceof Array);
        assert.strictEqual(options.data.length, 0);
      });

      it('should default key to null', async () => {
        await sut.start(options);
        assert.strictEqual(options.key, defaults.key);
      });

      it('should default cert to null', async () => {
        await sut.start(options);
        assert.strictEqual(options.cert, defaults.cert);
      });
    });
  });
});
