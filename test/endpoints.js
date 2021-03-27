'use strict';

let sut;
const Endpoints = require('../src/models/endpoints').Endpoints;
const sinon = require('sinon');
const assert = require('assert');
const bufferEqual = require('./helpers/buffer-equal');

describe('Endpoints', function () {
  beforeEach(function () {
    sut = new Endpoints();
  });

  describe('operations', function () {
    afterEach(function () {
      sinon.restore();
    });

    describe('create', function () {
      let data;

      beforeEach(function () {
        data = {
          request: {
            url: ''
          }
        };
      });

      it('should assign id to entered endpoint', () => {
        sut.create(data);

        assert.notStrictEqual(sut.db[1], undefined);
        assert.strictEqual(sut.db[2], undefined);
      });

      it('should call return created item', () => {
        const item = sut.create(data);

        assert(item != null);
      });

      it('should assign ids to entered endpoints', () => {
        sut.create([data, data]);

        assert.notStrictEqual(sut.db[1], undefined);
        assert.notStrictEqual(sut.db[2], undefined);
        assert.strictEqual(sut.db[3], undefined);
      });

      it('should call callback for each supplied endpoint', () => {
        const results = sut.create([data, data]);

        assert(results.length === 2);
      });
    });

    describe('retrieve', function () {
      const id = 'any id';

      it('should resolve row if operation returns a row', () => {
        const row = {
          request: {},
          response: {}
        };
        sut.db[id] = row;

        const actual = sut.retrieve(id);

        assert(actual);
      });

      it('should throw with error msg if operation does not find item', () => {
        sut.db = [];

        assert.throws(() => { sut.retrieve(id); }, {
          message: "Endpoint with the given id doesn't exist."
        });
      });
    });

    describe('update', function () {
      const id = 'any id';
      const data = {
        request: {
          url: ''
        }
      };

      it('should not throw when database updates', () => {
        sut.db[id] = {};

        sut.update(id, data);
        assert(Object.prototype.hasOwnProperty.call(sut.db[id], 'request'));
      });

      it('should reject with error msg if operation does not find item', async () => {
        assert.rejects(async () => { await sut.update(id, data); }, {
          message: "Endpoint with the given id doesn't exist."
        });
      });
    });

    describe('delete', function () {
      const id = 'any id';

      it('should resolve when database updates', async () => {
        sut.db[id] = {};

        await sut.delete(id);
      });

      it('should reject with error message if operation does not find item', async () => {
        assert.rejects(async () => { await sut.delete(id); }, {
          message: "Endpoint with the given id doesn't exist."
        });
      });
    });

    describe('gather', function () {
      it('should resolve with rows if operation returns some rows', async () => {
        const data = [{}, {}];
        sut.db = data;

        const actual = await sut.gather();

        assert.deepStrictEqual(actual, data);
      });

      it('should resolve with empty array if operation does not find item', async () => {
        sut.db = [];

        const actual = await sut.gather();

        assert.deepStrictEqual(actual, []);
      });
    });

    describe('find', function () {
      let data = {
        method: 'GET'
      };

      it('should resolve with row if operation returns a row', async () => {
        await sut.create({});
        assert(await sut.find(data));
      });

      it('should reject with error if operation does not find item', async () => {
        await assert.rejects(async () => { await sut.find(data); }, {
          message: "Endpoint with given request doesn't exist."
        });
      });

      describe('dynamic templating', function () {
        it('should replace all captures in body', async () => {
          await sut.create({
            request: {
              url: '/',
              post: '.*'
            },
            response: {
              body: 'you posted "<% post[0] %>" and "<% post[0] %>"'
            }
          });

          data = {
            url: '/',
            method: 'GET',
            post: 'hello, there!'
          };

          const match = await sut.find(data);
          assert.strictEqual(match.body, 'you posted "hello, there!" and "hello, there!"');
        });

        it('should replace captures in a text file', async () => {
          const expected = 'file contents!';
          data = {
            url: '/',
            method: 'GET',
            post: 'endpoints'
          };

          await sut.create({
            request: {
              url: '/',
              post: '.*'
            },
            response: {
              file: 'test/data/<% post[0] %>.file'
            }
          });

          const found = await sut.find(data);

          assert.strictEqual(found.body.toString().trim(), expected);
        });

        it('should return binary data unmolested', async () => {
          const expected = Buffer.from([0x80, 0x81, 0x82, 0xab, 0xcd, 0xef, 0x3c, 0x25, 0x20, 0x70, 0x6f, 0x73, 0x74, 0x5b, 0x30, 0x5d, 0x20, 0x25, 0x3e, 0xfe, 0xdc, 0xba, 0x82, 0x81, 0x80]);
          data = {
            url: '/',
            method: 'GET',
            post: 'binary'
          };

          await sut.create({
            request: {
              url: '/',
              post: '.*'
            },
            response: {
              file: 'test/data/<% post[0] %>.file'
            }
          });

          const found = await sut.find(data);
          const body = found.body;

          assert(body instanceof Buffer);
          assert(bufferEqual(body, expected));
        });
      });

      describe('request json versus post or file', function () {
        it('should not match response if the request json does not match the incoming post', async () => {
          const expected = 'Endpoint with given request doesn\'t exist.';

          await sut.create({
            request: {
              url: '/testing',
              json: '{"key2":"value2", "key1":"value1"}',
              method: 'post'
            },
            response: 200
          });

          data = {
            method: 'POST',
            url: '/testing',
            post: '{"key1": "value1", "key3":"value3"}'
          };

          await assert.rejects(async () => { await sut.find(data); }, {
            message: expected
          });
        });

        it('should match response with json if json is supplied and neither post nor file are supplied', async () => {
          const expected = {
            status: 200
          };
          await sut.create({
            request: {
              url: '/testing',
              json: '{"key2":"value2", "key1":"value1"}',
              method: 'post'
            },
            response: expected
          });
          data = {
            method: 'POST',
            url: '/testing',
            post: '{"key1": "value1", "key2":"value2"}'
          };

          const found = await sut.find(data);

          assert.equal(found.status, 200);
        });

        it('should match response with post if post is supplied', async () => {
          const expected = {
            status: 200
          };
          await sut.create({
            request: {
              url: '/testing',
              json: '{"key":"value"}',
              post: 'the post!',
              method: 'post'
            },
            response: expected
          });
          data = {
            method: 'POST',
            url: '/testing',
            post: 'the post!'
          };
          const found = await sut.find(data);

          assert.equal(found.status, 200);
        });

        it('should match response with file if file is supplied', async () => {
          const expected = {
            status: 200
          };
          await sut.create({
            request: {
              url: '/testing',
              file: 'test/data/endpoints.file',
              json: '{"key":"value"}',
              method: 'post'
            },
            response: expected
          });
          data = {
            method: 'POST',
            url: '/testing',
            post: 'file contents!'
          };

          await sut.find(data);
        });
      });

      describe('request post versus file', function () {
        it('should match response with post if file is not supplied', async () => {
          const expected = {
            status: 200
          };
          await sut.create({
            request: {
              url: '/testing',
              post: 'the post!',
              method: 'post'
            },
            response: expected
          });
          data = {
            method: 'POST',
            url: '/testing',
            post: 'the post!'
          };
          await sut.find(data);
        });

        it('should match response with post file is supplied but cannot be found', async () => {
          const expected = {
            status: 200
          };
          await sut.create({
            request: {
              url: '/testing',
              file: 'test/data/endpoints-nonexistant.file',
              post: 'post data!',
              method: 'post'
            },
            response: expected
          });
          data = {
            method: 'POST',
            url: '/testing',
            post: 'post data!'
          };
          assert(await sut.find(data));
        });

        it('should match response with file if file is supplied and exists', async () => {
          const expected = {
            status: 200
          };
          await sut.create({
            request: {
              url: '/testing',
              file: 'test/data/endpoints.file',
              post: 'post data!',
              method: 'post'
            },
            response: expected
          });
          data = {
            url: '/testing',
            post: 'file contents!',
            method: 'POST'
          };
          assert(await sut.find(data));
        });
      });

      describe('post versus form', function () {
        it('should match response with form params', async () => {
          const expected = {
            status: 200
          };
          await sut.create({
            request: {
              url: '/testing',
              form: { email: 'name@mail.com', var2: 'val2' },
              method: 'post'
            },
            response: expected
          });
          data = {
            url: '/testing',
            post: 'email=name%40mail.com&var2=val2',
            method: 'POST'
          };
          assert(await sut.find(data));
        });

        it('should not match response with incorrect form params', async () => {
          const expected = {
            status: 200
          };
          await sut.create({
            request: {
              url: '/testing',
              form: { email: 'name@mail.com' },
              method: 'post'
            },
            response: expected
          });
          data = {
            url: '/testing',
            post: 'email=fail%40mail.com',
            method: 'POST'
          };
          await assert.rejects(async () => { await sut.find(data); }, {
            message: 'Endpoint with given request doesn\'t exist.'
          });
        });

        it('should match response with extra form params', async () => {
          const expected = {
            status: 200
          };
          await sut.create({
            request: {
              url: '/testing',
              form: { email: 'name@mail.com' },
              method: 'post'
            },
            response: expected
          });
          data = {
            url: '/testing',
            post: 'email=name%40mail.com&var2=val2',
            method: 'POST'
          };
          assert(await sut.find(data));
        });

        it('should not match response with form params, if params not supplied', async () => {
          const expected = {
            status: 200
          };
          await sut.create({
            request: {
              url: '/testing',
              form: { var1: 'val1', var2: 'val2' },
              method: 'post'
            },
            response: expected
          });
          data = {
            url: '/testing',
            post: 'var3=val3',
            method: 'POST'
          };
          await assert.rejects(async () => { await sut.find(data); }, {
            message: "Endpoint with given request doesn't exist."
          });
        });
      });

      describe('response body versus file', function () {
        it('should return response with body as content if file is not supplied', async () => {
          const expected = 'the body!';
          await sut.create({
            request: {
              url: '/testing'
            },
            response: {
              body: expected
            }
          });
          data = {
            url: '/testing',
            method: 'GET'
          };
          const found = await sut.find(data);

          assert.strictEqual(found.body.toString(), expected);
        });

        it('should return response with body as content if file is supplied but cannot be found', async () => {
          const expected = 'the body!';
          await sut.create({
            request: {
              url: '/testing'
            },
            response: {
              body: expected,
              file: 'test/data/endpoints-nonexistant.file'
            }
          });
          data = {
            url: '/testing',
            method: 'GET'
          };
          const found = await sut.find(data);

          assert.strictEqual(found.body.toString(), expected);
        });

        it('should return response with file as content if file is supplied and exists', async () => {
          const expected = 'file contents!';
          await sut.create({
            request: {
              url: '/testing'
            },
            response: {
              body: 'body contents!',
              file: 'test/data/endpoints.file'
            }
          });
          data = {
            url: '/testing',
            method: 'GET'
          };
          const found = await sut.find(data);

          assert.strictEqual(found.body.toString().trim(), expected);
        });
      });

      describe('method', function () {
        it('should return response even if cases match', async () => {
          await sut.create({
            request: {
              method: 'POST'
            },
            response: {}
          });
          data = {
            method: 'POST'
          };
          assert(await sut.find(data) != null);
        });

        it('should return response even if cases do not match', async () => {
          await sut.create({
            request: {
              method: 'post'
            },
            response: {}
          });
          data = {
            method: 'POST'
          };
          assert(await sut.find(data) != null);
        });

        it('should return response if method matches any of the defined', async () => {
          await sut.create({
            request: {
              method: ['post', 'put']
            },
            response: {}
          });
          data = {
            method: 'POST'
          };
          assert(await sut.find(data) != null);
        });

        it('should call callback with error if none of the methods match', async () => {
          await sut.create({
            request: {
              method: ['post', 'put']
            },
            response: {}
          });
          data = {
            method: 'GET'
          };
          await assert.rejects(async () => { await sut.find(data); }, {
            message: "Endpoint with given request doesn't exist."
          });
        });
      });

      describe('headers', function () {
        it('should return response if all headers of request match', async () => {
          await sut.create({
            request: {
              headers: {
                'content-type': 'application/json'
              }
            },
            response: {}
          });
          data = {
            method: 'GET',
            headers: {
              'content-type': 'application/json'
            }
          };
          await sut.find(data);
        });

        it('should call callback with error if all headers of request dont match', async () => {
          await sut.create({
            request: {
              headers: {
                'content-type': 'application/json'
              }
            },
            response: {}
          });
          data = {
            method: 'GET',
            headers: {
              authentication: 'Basic gibberish:password'
            }
          };
          await assert.rejects(async () => { await sut.find(data); }, {
            message: "Endpoint with given request doesn't exist."
          });
        });
      });

      describe('query', function () {
        it('should return response if all query of request match', async () => {
          await sut.create({
            request: {
              query: {
                first: 'value1'
              }
            },
            response: {}
          });
          data = {
            method: 'GET',
            query: {
              first: 'value1'
            }
          };
          await sut.find(data);
        });

        it('should reject with error if all query of request dont match', async () => {
          await sut.create({
            request: {
              query: {
                first: 'value1'
              }
            },
            response: {}
          });
          data = {
            method: 'GET',
            query: {
              unknown: 'good question'
            }
          };
          await assert.rejects(async () => { await sut.find(data); }, {
            message: "Endpoint with given request doesn't exist."
          });
        });
      });
    });
  });
});
