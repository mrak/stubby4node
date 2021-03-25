'use strict';

const sut = require('../src/models/contract');
const assert = require('assert');

describe('contract', function () {
  let data;

  beforeEach(function () {
    data = {
      request: {
        url: 'something',
        method: 'POST',
        query: {
          first: 'value1',
          second: 'value2'
        },
        post: 'form data',
        headers: {
          property: 'value'
        },
        auth: {
          username: 'Afmrak',
          password: 'stubby'
        }
      },
      response: {
        headers: {
          property: 'value'
        },
        status: 204,
        body: 'success!',
        latency: 5000
      }
    };
  });

  it('should return no errors for valid data', function () {
    const result = sut(data);

    assert.strictEqual(result, null);
  });

  it('should return no errors for an array of valid data', function () {
    data = [data, data];
    const result = sut(data);

    assert.strictEqual(result, null);
  });

  it('should return an array of errors when multiple problems are found', function () {
    const expected = [["'response.status' must be integer-like."], ["'request.url' is required.", "'request.method' must be one of GET,PUT,POST,HEAD,PATCH,TRACE,DELETE,CONNECT,OPTIONS.", "'response.headers', if supplied, must be an object."]];
    const data2 = {
      request: {
        method: 'INVALID'
      },
      response: {
        headers: []
      }
    };
    data.response.status = 'a string';

    const results = sut([data, data2]);
    assert.deepStrictEqual(results, expected);
  });

  it('should return array of errors for an array with an invalid datum', function () {
    const invalid = {};
    data = [data, invalid];

    const result = sut(data);

    assert.strictEqual(result.length, 1);
  });

  describe('request', function () {
    it('should return error when missing', function () {
      let actual;
      const expected = ["'request' object is required."];

      delete data.request;
      actual = sut(data);
      assert.deepStrictEqual(actual, expected);

      data.request = null;
      actual = sut(data);
      assert.deepStrictEqual(actual, expected);
    });

    describe('query', function () {
      it('should have no errors when absent', function () {
        let result;

        delete data.request.query;
        result = sut(data);
        assert.strictEqual(result, null);

        data.request.query = null;
        result = sut(data);
        assert.strictEqual(result, null);
      });

      it('cannot be an array', function () {
        const expected = ["'request.query', if supplied, must be an object."];
        data.request.query = ['one', 'two'];

        const actual = sut(data);

        assert.deepStrictEqual(actual, expected);
      });

      it('cannot be a string', function () {
        const expected = ["'request.query', if supplied, must be an object."];
        data.request.query = 'one';

        const actual = sut(data);

        assert.deepStrictEqual(actual, expected);
      });
    });

    describe('headers', function () {
      it('should have no errors when absent', function () {
        let result;

        data.request.headers = null;
        result = sut(data);
        assert.strictEqual(result, null);

        delete data.request.headers;
        result = sut(data);
        assert.strictEqual(result, null);
      });

      it('cannot be an array', function () {
        const expected = ["'request.headers', if supplied, must be an object."];
        data.request.headers = ['one', 'two'];

        const actual = sut(data);

        assert.deepStrictEqual(actual, expected);
      });

      it('cannot be a string', function () {
        const expected = ["'request.headers', if supplied, must be an object."];
        data.request.headers = 'one';

        const actual = sut(data);

        assert.deepStrictEqual(actual, expected);
      });
    });

    describe('url', function () {
      it('should return error for a missing url', function () {
        let result;
        const expected = ["'request.url' is required."];

        data.request.url = null;
        result = sut(data);
        assert.deepStrictEqual(result, expected);

        delete data.request.url;
        result = sut(data);
        assert.deepStrictEqual(result, expected);
      });
    });

    describe('method', function () {
      it('should accept an array of methods', function () {
        data.request.method = ['put', 'post', 'get'];

        const result = sut(data);

        assert.strictEqual(result, null);
      });

      it('should accept lowercase methods', function () {
        data.request.method = 'put';

        const result = sut(data);

        assert.strictEqual(result, null);
      });

      it('should have no errors for a missing method (defaults to GET)', function () {
        let result;

        data.request.method = null;
        result = sut(data);
        assert.strictEqual(result, null);

        delete data.request.method;
        result = sut(data);
        assert.strictEqual(result, null);
      });

      it('should return error if method isnt HTTP 1.1', function () {
        const expected = ["'request.method' must be one of GET,PUT,POST,HEAD,PATCH,TRACE,DELETE,CONNECT,OPTIONS."];
        data.request.method = 'QUEST';

        const result = sut(data);

        assert.deepStrictEqual(result, expected);
      });
    });

    it('should return no errors for a missing post field', function () {
      let result;

      data.request.post = null;
      result = sut(data);
      assert.strictEqual(result, null);

      delete data.request.post;
      result = sut(data);
      assert.strictEqual(result, null);
    });

    it('should return no errors for a missing json field', function () {
      let result;

      data.request.json = null;
      result = sut(data);
      assert.strictEqual(result, null);

      delete data.request.json;
      result = sut(data);
      assert.strictEqual(result, null);
    });
  });

  describe('response', function () {
    it('should be optional', function () {
      let result;

      data.response = null;
      result = sut(data);
      assert.strictEqual(result, null);

      delete data.response;
      result = sut(data);
      assert.strictEqual(result, null);
    });

    it('should be acceptable as a string', function () {
      data.response = 'http://www.google.com';

      const result = sut(data);

      assert.strictEqual(result, null);
    });

    it('should be acceptable as an array', function () {
      data.response = [{ status: 200 }];

      const result = sut(data);

      assert.strictEqual(result, null);
    });

    it('should return errors if a response in the array is invalid', function () {
      const expected = ["'response.status' must be < 600."];
      data.response = [{
        status: 200
      }, {
        status: 800
      }];

      const result = sut(data);

      assert.deepStrictEqual(result, expected);
    });

    describe('headers', function () {
      it('should return no errors when absent', function () {
        let result;

        data.response.headers = null;
        result = sut(data);
        assert.strictEqual(result, null);

        delete data.response.headers;
        result = sut(data);
        assert.strictEqual(result, null);
      });

      it('cannot be an array', function () {
        const expected = ["'response.headers', if supplied, must be an object."];
        data.response.headers = ['one', 'two'];

        const actual = sut(data);

        assert.deepStrictEqual(actual, expected);
      });

      it('cannot be a string', function () {
        const expected = ["'response.headers', if supplied, must be an object."];
        data.response.headers = 'one';

        const actual = sut(data);

        assert.deepStrictEqual(actual, expected);
      });
    });

    describe('status', function () {
      it('should return no erros when absent', function () {
        let result;

        data.response.status = null;
        result = sut(data);
        assert.strictEqual(result, null);

        delete data.response.status;
        result = sut(data);
        assert.strictEqual(result, null);
      });

      it('should return no errors when it is a number', function () {
        data.response.status = 400;

        const result = sut(data);

        assert.strictEqual(result, null);
      });

      it('should return no errors when it is a string of a number', function () {
        data.response.status = '400';

        const result = sut(data);

        assert.strictEqual(result, null);
      });

      it('cannot be a string that is not a number', function () {
        const expected = ["'response.status' must be integer-like."];
        data.response.status = 'string';

        const actual = sut(data);

        assert.deepStrictEqual(actual, expected);
      });

      it('cannot be an object', function () {
        const expected = ["'response.status' must be integer-like."];
        data.response.status = { property: 'value' };

        const actual = sut(data);

        assert.deepStrictEqual(actual, expected);
      });

      it('should return erros when less than 100', function () {
        const expected = ["'response.status' must be >= 100."];
        data.response.status = 99;

        const actual = sut(data);

        assert.deepStrictEqual(actual, expected);
      });

      it('should return erros when greater than or equal to 500', function () {
        const expected = ["'response.status' must be < 600."];
        data.response.status = 666;

        const actual = sut(data);

        assert.deepStrictEqual(actual, expected);
      });
    });

    describe('latency', function () {
      it('should return no errors when it is a number', function () {
        data.response.latency = 4000;

        const result = sut(data);

        assert.strictEqual(result, null);
      });

      it('should return no errors when it a string representation of a number', function () {
        data.response.latency = '4000';

        const result = sut(data);

        assert.strictEqual(result, null);
      });

      it('should return an error when a string cannot be parsed as a number', function () {
        const expected = ["'response.latency' must be integer-like."];
        data.response.latency = 'fred';

        const actual = sut(data);

        assert.deepStrictEqual(actual, expected);
      });
    });

    it('should return no errors for an empty body', function () {
      let result;

      data.response.body = null;
      result = sut(data);
      assert.strictEqual(result, null);

      delete data.response.body;
      result = sut(data);
      assert.strictEqual(result, null);
    });
  });
});
