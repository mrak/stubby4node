'use strict';

const Endpoint = require('../src/models/endpoint');
const assert = require('assert');
const waitsFor = require('./helpers/waits-for');

describe('Endpoint', function () {
  beforeEach(function () {
    this.data = {
      request: {}
    };
  });

  describe('matches', function () {
    it('should return regex captures for url', function () {
      this.data.request.url = '/capture/(.*)/$';
      const endpoint = new Endpoint(this.data);

      const actual = endpoint.matches({
        url: '/capture/me/',
        method: 'GET'
      });

      assert.strictEqual(actual.url[0], '/capture/me/');
      assert.strictEqual(actual.url[1], 'me');
    });

    it('should return regex captures for post', function () {
      this.data.request.url = '/';
      this.data.request.post = 'some sentence with a (\\w+) in it';
      const endpoint = new Endpoint(this.data);

      const actual = endpoint.matches({
        url: '/',
        method: 'GET',
        post: 'some sentence with a word in it'
      });

      assert.strictEqual(actual.post[1], 'word');
    });

    it('should return regex captures for headers', function () {
      this.data.request.url = '/';
      this.data.request.headers = {
        'content-type': 'application/(\\w+)'
      };
      const endpoint = new Endpoint(this.data);

      const actual = endpoint.matches({
        url: '/',
        method: 'GET',
        headers: {
          'content-type': 'application/json'
        }
      });

      assert.strictEqual(actual.headers['content-type'][1], 'json');
    });

    it('should return regex captures for query', function () {
      this.data.request.url = '/';
      this.data.request.query = {
        variable: '.*'
      };
      const endpoint = new Endpoint(this.data);

      const actual = endpoint.matches({
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
      const waitTime = 10000;
      this.timeout(waitTime);
      this.data.response = 'http://google.com';

      const actual = new Endpoint(this.data);

      waitsFor(function () {
        return actual.response[0].status === 301;
      }, 'endpoint to record', waitTime, done);
    });

    it('should fill in a string reponse with the recorded endpoint in series', function (done) {
      const waitTime = 10000;
      this.timeout(waitTime);
      this.data.response = ['http://google.com', 'http://example.com'];

      const actual = new Endpoint(this.data);

      waitsFor(function () {
        return actual.response[0].status === 301 && actual.response[1].status === 200;
      }, 'endpoint to record', waitTime, done);
    });

    it('should fill in a string reponse with the recorded endpoint in series', function (done) {
      const waitTime = 10000;
      this.timeout(waitTime);
      const data = {
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

      const actual = new Endpoint(data);

      waitsFor(function () {
        return actual.response[0].status === 301 && actual.response[1].status === 420;
      }, 'endpoint to record', waitTime, done);
    });
  });

  describe('constructor', function () {
    it('should at least copy over valid data', function () {
      const data = {
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
      const actual = new Endpoint(data);
      const actualbody = actual.response[0].body.toString();
      const actualJSON = actual.request.json;

      delete actual.response[0].body;
      const expectedBody = data.response[0].body;
      delete data.response[0].body;

      delete actual.request.json;
      const expectedJSON = JSON.parse(data.request.json);
      delete data.request.json;

      ['hits', 'request', 'response'].forEach(key => {
        assert.deepStrictEqual(actual[key], data[key]);
      });
      assert.strictEqual(expectedBody, actualbody);
      assert.deepStrictEqual(actualJSON, expectedJSON);
    });

    it('should default method to GET', function () {
      const expected = 'GET';

      const actual = new Endpoint(this.data);

      assert.strictEqual(actual.request.method, expected);
    });

    it('should default status to 200', function () {
      const expected = 200;
      const actual = new Endpoint(this.data);

      assert.strictEqual(actual.response[0].status, expected);
    });

    it('should lower case headers properties', function () {
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
      const expected = {
        request: {
          'content-type': 'application/json'
        },
        response: {
          'content-type': 'application/json'
        }
      };

      const actual = new Endpoint(this.data);

      assert.deepStrictEqual(actual.response[0].headers, expected.response);
      assert.deepStrictEqual(actual.request.headers, expected.request);
    });

    it('should not lower case response headers properties if caseSensitiveHeaders is true', function () {
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
      const expected = {
        request: {
          'content-type': 'application/json'
        },
        response: {
          'Content-Type': 'application/json'
        }
      };

      const actual = new Endpoint(this.data, null, true);

      assert.deepStrictEqual(actual.response[0].headers, expected.response);
      assert.deepStrictEqual(actual.request.headers, expected.request);
    });

    it('should define multiple headers with same name', function () {
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
      const expected = {
        request: {
          'content-type': 'application/json'
        },
        response: {
          'content-type': 'application/json',
          'set-cookie': ['type=ninja', 'language=coffeescript']
        }
      };

      const actual = new Endpoint(this.data);

      assert.deepStrictEqual(actual.response[0].headers, expected.response);
      assert.deepStrictEqual(actual.request.headers, expected.request);
    });

    it('should base64 encode authorization headers if not encoded', function () {
      const expected = 'Basic dXNlcm5hbWU6cGFzc3dvcmQ=';
      this.data.request.headers = {
        authorization: 'Basic username:password'
      };

      const actual = new Endpoint(this.data);

      assert.strictEqual(actual.request.headers.authorization, expected);
    });

    it('should not encode authorization headers if encoded', function () {
      const expected = 'Basic dXNlcm5hbWU6cGFzc3dvc=';
      this.data.request.headers = {
        authorization: 'Basic dXNlcm5hbWU6cGFzc3dvc='
      };

      const actual = new Endpoint(this.data);

      assert.strictEqual(actual.request.headers.authorization, expected);
    });

    it('should stringify object body in response', function () {
      const expected = '{"property":"value"}';
      this.data.response = {
        body: {
          property: 'value'
        }
      };

      const actual = new Endpoint(this.data);

      assert.strictEqual(actual.response[0].body.toString(), expected);
    });

    it('should JSON parse the object json in request', function () {
      const expected = {
        key: 'value'
      };
      this.data.request = {
        json: '{"key":"value"}'
      };

      const actual = new Endpoint(this.data);
      assert.deepStrictEqual(actual.request.json, expected);
    });

    it('should get the Origin header', function () {
      const expected = 'http://example.org';
      this.data.request.headers = {
        Origin: 'http://example.org'
      };

      const actual = new Endpoint(this.data);

      assert.strictEqual(actual.request.headers.origin, expected);
    });

    it('should define aditional Cross-Origin headers', function () {
      const expected = 'http://example.org';
      this.data.request.headers = {
        Origin: 'http://example.org',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type, origin'
      };

      const actual = new Endpoint(this.data);

      assert.strictEqual(actual.request.headers.origin, expected);
      assert.strictEqual(actual.request.headers['access-control-request-method'], 'POST');
      assert.strictEqual(actual.request.headers['access-control-request-headers'], 'Content-Type, origin');
    });
  });
});
