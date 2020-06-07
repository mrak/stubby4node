'use strict';

var Endpoint = require('../src/models/endpoint');
var assert = require('assert');

function waitsFor (fn, message, range, finish, time) {
  var temp, seconds, nanoseconds, elapsed;
  var min = range[0] != null ? range[0] : 0;
  var max = range[1] != null ? range[1] : range;

  if (time == null) { time = process.hrtime(); }

  temp = time == null ? process.hrtime() : process.hrtime(time);
  seconds = temp[0];
  nanoseconds = temp[1];
  elapsed = seconds * 1000 + nanoseconds / 1000000;

  assert(elapsed < max, 'Timed out waiting ' + max + 'ms for ' + message);

  if (fn()) {
    assert(elapsed > min, 'Condition succeeded before ' + min + 'ms were up');
    return finish();
  }

  setTimeout(function () {
    waitsFor(fn, message, range, finish, time);
  }, 1);
}

function compareOneWay (left, right) {
  var key, value;

  for (key in left) {
    if (!Object.prototype.hasOwnProperty.call(left, key)) { continue; }

    value = left[key];

    if (right[key] !== value) { continue; }

    if (typeof value === 'object') {
      if (!compareObjects(value, right[key])) { continue; }
    }

    return false;
  }

  return true;
}

function compareObjects (one, two) {
  return compareOneWay(one, two) && compareOneWay(two, one);
}

describe('Endpoint', function () {
  beforeEach(function () {
    this.data = {
      request: {}
    };
  });

  describe('matches', function () {
    it('should return regex captures for url', function () {
      var actual, endpoint;
      this.data.request.url = '/capture/(.*)/$';
      endpoint = new Endpoint(this.data);

      actual = endpoint.matches({
        url: '/capture/me/',
        method: 'GET'
      });

      assert.strictEqual(actual.url[0], '/capture/me/');
      assert.strictEqual(actual.url[1], 'me');
    });

    it('should return regex captures for post', function () {
      var actual, endpoint;
      this.data.request.url = '/';
      this.data.request.post = 'some sentence with a (\\w+) in it';
      endpoint = new Endpoint(this.data);

      actual = endpoint.matches({
        url: '/',
        method: 'GET',
        post: 'some sentence with a word in it'
      });

      assert.strictEqual(actual.post[1], 'word');
    });

    it('should return regex captures for headers', function () {
      var actual, endpoint;
      this.data.request.url = '/';
      this.data.request.headers = {
        'content-type': 'application/(\\w+)'
      };
      endpoint = new Endpoint(this.data);

      actual = endpoint.matches({
        url: '/',
        method: 'GET',
        headers: {
          'content-type': 'application/json'
        }
      });

      assert.strictEqual(actual.headers['content-type'][1], 'json');
    });

    it('should return regex captures for query', function () {
      var actual, endpoint;
      this.data.request.url = '/';
      this.data.request.query = {
        variable: '.*'
      };
      endpoint = new Endpoint(this.data);

      actual = endpoint.matches({
        url: '/',
        method: 'GET',
        query: {
          variable: 'value'
        }
      });

      assert.strictEqual(actual.query.variable[0], 'value');
    });
  });

  describe('recording', function () {
    it('should fill in a string response with the recorded endpoint', function (done) {
      var actual;
      var waitTime = 10000;
      this.timeout(waitTime);
      this.data.response = 'http://google.com';

      actual = new Endpoint(this.data);

      waitsFor(function () {
        return actual.response[0].status === 301;
      }, 'endpoint to record', waitTime, done);
    });

    it('should fill in a string reponse with the recorded endpoint in series', function (done) {
      var actual;
      var waitTime = 10000;
      this.timeout(waitTime);
      this.data.response = ['http://google.com', 'http://example.com'];

      actual = new Endpoint(this.data);

      waitsFor(function () {
        return actual.response[0].status === 301 && actual.response[1].status === 200;
      }, 'endpoint to record', waitTime, done);
    });

    it('should fill in a string reponse with the recorded endpoint in series', function (done) {
      var actual, data;
      var waitTime = 10000;
      this.timeout(waitTime);
      data = {
        request: {
          url: '/',
          method: 'GET',
          query: {
            s: 'value'
          }
        },
        response: [
          'http://google.com',
          { status: 420 }
        ]
      };

      actual = new Endpoint(data);

      waitsFor(function () {
        return actual.response[0].status === 301 && actual.response[1].status === 420;
      }, 'endpoint to record', waitTime, done);
    });
  });

  describe('constructor', function () {
    it('should at least copy over valid data', function () {
      var expectedBody, expectedJSON;
      var data = {
        hits: 0,
        request: {
          url: '/',
          method: 'post',
          query: {
            variable: 'value'
          },
          headers: {
            header: 'string'
          },
          post: 'data',
          file: 'file.txt',
          json: '{"key":"value"}'
        },
        response: [{
          latency: 3000,
          body: 'contents',
          file: 'another.file',
          status: 420,
          headers: {
            'access-control-allow-origin': '*'
          }
        }]
      };
      var actual = new Endpoint(data);
      var actualbody = actual.response[0].body.toString();
      var actualJSON = actual.request.json;

      delete actual.response[0].body;
      expectedBody = data.response[0].body;
      delete data.response[0].body;

      delete actual.request.json;
      expectedJSON = JSON.parse(data.request.json);
      delete data.request.json;

      ['hits', 'request', 'response'].forEach(key => {
        assert.deepStrictEqual(actual[key], data[key]);
      });
      assert.strictEqual(expectedBody, actualbody);
      assert.deepStrictEqual(actualJSON, expectedJSON);
    });

    it('should default method to GET', function () {
      var expected = 'GET';

      var actual = new Endpoint(this.data);

      assert.strictEqual(actual.request.method, expected);
    });

    it('should default status to 200', function () {
      var expected = 200;
      var actual = new Endpoint(this.data);

      assert.strictEqual(actual.response[0].status, expected);
    });

    it('should lower case headers properties', function () {
      var actual, expected;
      this.data.request = {
        headers: {
          'Content-Type': 'application/json'
        }
      };
      this.data.response = {
        headers: {
          'Content-Type': 'application/json'
        }
      };
      expected = {
        request: {
          'content-type': 'application/json'
        },
        response: {
          'content-type': 'application/json'
        }
      };

      actual = new Endpoint(this.data);

      assert.deepStrictEqual(actual.response[0].headers, expected.response);
      assert.deepStrictEqual(actual.request.headers, expected.request);
    });

    it('should not lower case response headers properties if dittoResponse is true', function () {
      var actual, expected;
      this.data.request = {
        headers: {
          'Content-Type': 'application/json'
        }
      };
      this.data.response = {
        headers: {
          'Content-Type': 'application/json'
        }
      };
      expected = {
        request: {
          'content-type': 'application/json'
        },
        response: {
          'Content-Type': 'application/json'
        }
      };

      actual = new Endpoint(this.data, null, true);

      assert.deepStrictEqual(actual.response[0].headers, expected.response);
      assert.deepStrictEqual(actual.request.headers, expected.request);
    });

    it('should define multiple headers with same name', function () {
      var actual, expected;
      this.data.request = {
        headers: {
          'Content-Type': 'application/json'
        }
      };
      this.data.response = {
        headers: {
          'Content-Type': 'application/json',
          'Set-Cookie': ['type=ninja', 'language=coffeescript']
        }
      };
      expected = {
        request: {
          'content-type': 'application/json'
        },
        response: {
          'content-type': 'application/json',
          'set-cookie': ['type=ninja', 'language=coffeescript']
        }
      };

      actual = new Endpoint(this.data);

      assert.deepStrictEqual(actual.response[0].headers, expected.response);
      assert.deepStrictEqual(actual.request.headers, expected.request);
    });

    it('should base64 encode authorization headers if not encoded', function () {
      var actual, expected;
      expected = 'Basic dXNlcm5hbWU6cGFzc3dvcmQ=';
      this.data.request.headers = {
        authorization: 'Basic username:password'
      };

      actual = new Endpoint(this.data);

      assert.strictEqual(actual.request.headers.authorization, expected);
    });

    it('should not encode authorization headers if encoded', function () {
      var actual, expected;
      expected = 'Basic dXNlcm5hbWU6cGFzc3dvc=';
      this.data.request.headers = {
        authorization: 'Basic dXNlcm5hbWU6cGFzc3dvc='
      };

      actual = new Endpoint(this.data);

      assert.strictEqual(actual.request.headers.authorization, expected);
    });

    it('should stringify object body in response', function () {
      var actual, expected;
      expected = '{"property":"value"}';
      this.data.response = {
        body: {
          property: 'value'
        }
      };

      actual = new Endpoint(this.data);

      assert.strictEqual(actual.response[0].body.toString(), expected);
    });

    it('should JSON parse the object json in request', function () {
      var actual, expected;
      expected = {
        key: 'value'
      };
      this.data.request = {
        json: '{"key":"value"}'
      };

      actual = new Endpoint(this.data);
      assert.deepStrictEqual(actual.request.json, expected);
    });

    it('should get the Origin header', function () {
      var actual, expected;
      expected = 'http://example.org';
      this.data.request.headers = {
        Origin: 'http://example.org'
      };

      actual = new Endpoint(this.data);

      assert.strictEqual(actual.request.headers.origin, expected);
    });

    it('should define aditional Cross-Origin headers', function () {
      var actual, expected;
      expected = 'http://example.org';
      this.data.request.headers = {
        Origin: 'http://example.org',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type, origin'
      };

      actual = new Endpoint(this.data);

      assert.strictEqual(actual.request.headers.origin, expected);
      assert.strictEqual(actual.request.headers['access-control-request-method'], 'POST');
      assert.strictEqual(actual.request.headers['access-control-request-headers'], 'Content-Type, origin');
    });
  });
});
