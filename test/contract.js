'use strict';

var sut = require('../src/models/contract');
var assert = require('assert');

describe('contract', function () {
  var data;

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
    var result = sut(data);

    assert(result === null);
  });

  it('should return no errors for an array of valid data', function () {
    var result;

    data = [data, data];
    result = sut(data);

    assert(result === null);
  });

  it('should return an array of errors when multiple problems are found', function () {
    var results;
    var expected = [["'response.status' must be integer-like."], ["'request.url' is required.", "'request.method' must be one of GET,PUT,POST,HEAD,PATCH,TRACE,DELETE,CONNECT,OPTIONS.", "'response.headers', if supplied, must be an object."]];
    var data2 = {
      request: {
        method: 'INVALID'
      },
      response: {
        headers: []
      }
    };
    data.response.status = 'a string';

    results = sut([data, data2]);
    assert.deepEqual(results, expected);
  });

  it('should return array of errors for an array with an invalid datum', function () {
    var result;
    var invalid = {};
    data = [data, invalid];

    result = sut(data);

    assert(result.length === 1);
  });

  describe('request', function () {
    it('should return error when missing', function () {
      var actual;
      var expected = ["'request' object is required."];

      delete data.request;
      actual = sut(data);
      assert.deepEqual(actual, expected);

      data.request = null;
      actual = sut(data);
      assert.deepEqual(actual, expected);
    });

    describe('query', function () {
      it('should have no errors when absent', function () {
        var result;

        delete data.request.query;
        result = sut(data);
        assert(result === null);

        data.request.query = null;
        result = sut(data);
        assert(result === null);
      });

      it('cannot be an array', function () {
        var actual;
        var expected = ["'request.query', if supplied, must be an object."];
        data.request.query = ['one', 'two'];

        actual = sut(data);

        assert.deepEqual(actual, expected);
      });

      it('cannot be a string', function () {
        var actual;
        var expected = ["'request.query', if supplied, must be an object."];
        data.request.query = 'one';

        actual = sut(data);

        assert.deepEqual(actual, expected);
      });
    });

    describe('headers', function () {
      it('should have no errors when absent', function () {
        var result;

        data.request.headers = null;
        result = sut(data);
        assert(result === null);

        delete data.request.headers;
        result = sut(data);
        assert(result === null);
      });

      it('cannot be an array', function () {
        var actual;
        var expected = ["'request.headers', if supplied, must be an object."];
        data.request.headers = ['one', 'two'];

        actual = sut(data);

        assert.deepEqual(actual, expected);
      });

      it('cannot be a string', function () {
        var actual;
        var expected = ["'request.headers', if supplied, must be an object."];
        data.request.headers = 'one';

        actual = sut(data);

        assert.deepEqual(actual, expected);
      });
    });

    describe('url', function () {
      it('should return error for a missing url', function () {
        var result;
        var expected = ["'request.url' is required."];

        data.request.url = null;
        result = sut(data);
        assert.deepEqual(result, expected);

        delete data.request.url;
        result = sut(data);
        assert.deepEqual(result, expected);
      });
    });

    describe('method', function () {
      it('should accept an array of methods', function () {
        var result;
        data.request.method = ['put', 'post', 'get'];

        result = sut(data);

        assert(result === null);
      });

      it('should accept lowercase methods', function () {
        var result;
        data.request.method = 'put';

        result = sut(data);

        assert(result === null);
      });

      it('should have no errors for a missing method (defaults to GET)', function () {
        var result;

        data.request.method = null;
        result = sut(data);
        assert(result === null);

        delete data.request.method;
        result = sut(data);
        assert(result === null);
      });

      it('should return error if method isnt HTTP 1.1', function () {
        var result;
        var expected = ["'request.method' must be one of GET,PUT,POST,HEAD,PATCH,TRACE,DELETE,CONNECT,OPTIONS."];
        data.request.method = 'QUEST';

        result = sut(data);

        assert.deepEqual(result, expected);
      });
    });

    it('should return no errors for a missing post field', function () {
      var result;

      data.request.post = null;
      result = sut(data);
      assert(result === null);

      delete data.request.post;
      result = sut(data);
      assert(result === null);
    });

    it('should return no errors for a missing json field', function () {
      var result;

      data.request.json = null;
      result = sut(data);
      assert(result === null);

      delete data.request.json;
      result = sut(data);
      assert(result === null);
    });
  });

  describe('response', function () {
    it('should be optional', function () {
      var result;

      data.response = null;
      result = sut(data);
      assert(result === null);

      delete data.response;
      result = sut(data);
      assert(result === null);
    });

    it('should be acceptable as a string', function () {
      var result;
      data.response = 'http://www.google.com';

      result = sut(data);

      assert(result === null);
    });

    it('should be acceptable as an array', function () {
      var result;
      data.response = [{status: 200}];

      result = sut(data);

      assert(result === null);
    });

    it('should return errors if a response in the array is invalid', function () {
      var result;
      var expected = ["'response.status' must be < 600."];
      data.response = [{
        status: 200
      }, {
        status: 800
      }];

      result = sut(data);

      assert.deepEqual(result, expected);
    });

    describe('headers', function () {
      it('should return no errors when absent', function () {
        var result;

        data.response.headers = null;
        result = sut(data);
        assert(result === null);

        delete data.response.headers;
        result = sut(data);
        assert(result === null);
      });

      it('cannot be an array', function () {
        var actual;
        var expected = ["'response.headers', if supplied, must be an object."];
        data.response.headers = ['one', 'two'];

        actual = sut(data);

        assert.deepEqual(actual, expected);
      });

      it('cannot be a string', function () {
        var actual;
        var expected = ["'response.headers', if supplied, must be an object."];
        data.response.headers = 'one';

        actual = sut(data);

        assert.deepEqual(actual, expected);
      });
    });

    describe('status', function () {
      it('should return no erros when absent', function () {
        var result;

        data.response.status = null;
        result = sut(data);
        assert(result === null);

        delete data.response.status;
        result = sut(data);
        assert(result === null);
      });

      it('should return no errors when it is a number', function () {
        var result;
        data.response.status = 400;

        result = sut(data);

        assert(result === null);
      });

      it('should return no errors when it is a string of a number', function () {
        var result;
        data.response.status = '400';

        result = sut(data);

        assert(result === null);
      });

      it('cannot be a string that is not a number', function () {
        var actual;
        var expected = ["'response.status' must be integer-like."];
        data.response.status = 'string';

        actual = sut(data);

        assert.deepEqual(actual, expected);
      });

      it('cannot be an object', function () {
        var actual;
        var expected = ["'response.status' must be integer-like."];
        data.response.status = {property: 'value'};

        actual = sut(data);

        assert.deepEqual(actual, expected);
      });

      it('should return erros when less than 100', function () {
        var actual;
        var expected = ["'response.status' must be >= 100."];
        data.response.status = 99;

        actual = sut(data);

        assert.deepEqual(actual, expected);
      });

      it('should return erros when greater than or equal to 500', function () {
        var actual;
        var expected = ["'response.status' must be < 600."];
        data.response.status = 666;

        actual = sut(data);

        assert.deepEqual(actual, expected);
      });
    });

    describe('latency', function () {
      it('should return no errors when it is a number', function () {
        var result;
        data.response.latency = 4000;

        result = sut(data);

        assert(result === null);
      });

      it('should return no errors when it a string representation of a number', function () {
        var result;
        data.response.latency = '4000';

        result = sut(data);

        assert(result === null);
      });

      it('should return an error when a string cannot be parsed as a number', function () {
        var actual;
        var expected = ["'response.latency' must be integer-like."];
        data.response.latency = 'fred';

        actual = sut(data);

        assert.deepEqual(actual, expected);
      });
    });

    it('should return no errors for an empty body', function () {
      var result;

      data.response.body = null;
      result = sut(data);
      assert(result === null);

      delete data.response.body;
      result = sut(data);
      assert(result === null);
    });
  });
});
