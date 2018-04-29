'use strict';

var Stubby = require('../src/main').Stubby;
var fs = require('fs');
var yaml = require('js-yaml');
var endpointData = yaml.load((fs.readFileSync('test/data/e2e.yaml', 'utf8')).trim());
var assert = require('assert');
var createRequest = require('./helpers/create-request');

describe('End 2 End Stubs Test Suite', function () {
  var sut = null;
  var port = 8882;

  function stopStubby (finish) {
    if (sut != null) {
      return sut.stop(finish);
    }
    return finish();
  }

  beforeEach(function (done) {
    this.context = {
      done: false,
      port: port
    };

    function finish () {
      sut = new Stubby();
      sut.start({
        data: endpointData
      }, done);
    }

    stopStubby(finish);
  });

  afterEach(stopStubby);

  describe('basics', function () {
    it('should return a basic GET endpoint', function (done) {
      this.context.url = '/basic/get';
      this.context.method = 'get';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.statusCode, 200);
        done();
      });
    });

    it('should return a basic PUT endpoint', function (done) {
      this.context.url = '/basic/put';
      this.context.method = 'put';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.statusCode, 200);
        done();
      });
    });

    it('should return a basic POST endpoint', function (done) {
      this.context.url = '/basic/post';
      this.context.method = 'post';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.statusCode, 200);
        done();
      });
    });

    it('should return a basic DELETE endpoint', function (done) {
      this.context.url = '/basic/delete';
      this.context.method = 'delete';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.statusCode, 200);
        done();
      });
    });

    it('should return a basic HEAD endpoint', function (done) {
      this.context.url = '/basic/head';
      this.context.method = 'head';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.statusCode, 200);
        done();
      });
    });

    it('should return a response for an endpoint with multiple methods', function (done) {
      var self = this;
      this.context.url = '/basic/all';
      this.context.method = 'delete';

      createRequest(self.context, function (response) {
        assert.strictEqual(response.statusCode, 200);
        self.context.finished = false;
        self.context.url = '/basic/all';
        self.context.method = 'get';

        createRequest(self.context, function (response2) {
          assert.strictEqual(response2.statusCode, 200);

          self.context.finished = false;
          self.context.url = '/basic/all';
          self.context.method = 'put';

          createRequest(self.context, function (response3) {
            assert.strictEqual(response3.statusCode, 200);

            self.context.finished = false;
            self.context.url = '/basic/all';
            self.context.method = 'post';

            createRequest(self.context, function (response4) {
              assert.strictEqual(response4.statusCode, 200);

              self.context.port = 8889;
              self.context.finished = false;
              self.context.url = '/6';
              self.context.method = 'get';

              createRequest(self.context, function (response5) {
                assert.strictEqual(response5.statusCode, 200);
                assert.strictEqual(JSON.parse(response5.data).hits, 4);
                done();
              });
            });
          });
        });
      });
    });

    it('should return the CORS headers', function (done) {
      var expected = 'http://example.org';
      this.context.url = '/basic/get';
      this.context.method = 'get';
      this.context.requestHeaders = {
        origin: expected
      };

      createRequest(this.context, function (response) {
        var headers = response.headers;

        assert.strictEqual(headers['access-control-allow-origin'], expected);
        assert.strictEqual(headers['access-control-allow-credentials'], 'true');
        done();
      });
    });

    it('should return multiple headers with the same name', function (done) {
      var expected = ['type=ninja', 'language=coffeescript'];
      this.context.url = '/duplicated/header';
      this.context.method = 'get';

      createRequest(this.context, function (response) {
        var headers = response.headers;

        assert.deepStrictEqual(headers['set-cookie'], expected);
        done();
      });
    });
  });

  describe('GET', function () {
    it('should return a body from a GET endpoint', function (done) {
      this.context.url = '/get/body';
      this.context.method = 'get';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.data, 'plain text');
        done();
      });
    });

    it('should return a body from a json GET endpoint', function (done) {
      this.context.url = '/get/json';
      this.context.method = 'get';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.data.trim(), '{"property":"value"}');
        assert.strictEqual(response.headers['content-type'], 'application/json');
        done();
      });
    });

    it('should return a 420 GET endpoint', function (done) {
      this.context.url = '/get/420';
      this.context.method = 'get';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.statusCode, 420);
        done();
      });
    });

    it('should be able to handle query params', function (done) {
      this.context.url = '/get/query';
      this.context.query = {
        first: 'value1 with spaces!',
        second: 'value2'
      };
      this.context.method = 'get';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.statusCode, 200);
        done();
      });
    });

    it('should return 404 if query params are not matched', function (done) {
      this.context.url = '/get/query';
      this.context.query = {
        first: 'invalid value',
        second: 'value2'
      };
      this.context.method = 'get';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.statusCode, 404);
        done();
      });
    });

    it('should comma-separate repeated query params', function (done) {
      this.context.url = '/query/array?array=one&array=two';
      this.context.method = 'get';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.statusCode, 200);
        assert.strictEqual(response.data, 'query as array works!');
        done();
      });
    });
  });

  describe('post', function () {
    it('should be able to handle authorized posts', function (done) {
      this.context.url = '/post/auth';
      this.context.method = 'post';
      this.context.post = 'some=data';
      this.context.requestHeaders = {
        authorization: 'Basic c3R1YmJ5OnBhc3N3b3Jk'
      };

      createRequest(this.context, function (response) {
        assert.strictEqual(response.statusCode, 201);
        assert.strictEqual(response.headers.location, '/some/endpoint/id');
        assert.strictEqual(response.data, 'resource has been created');
        done();
      });
    });

    it('should be able to handle authorized posts where the yaml wasnt pre-encoded', function (done) {
      this.context.url = '/post/auth/pair';
      this.context.method = 'post';
      this.context.post = 'some=data';
      this.context.requestHeaders = {
        authorization: 'Basic c3R1YmJ5OnBhc3N3b3JkWjBy'
      };

      createRequest(this.context, function (response) {
        assert.strictEqual(response.statusCode, 201);
        assert.strictEqual(response.headers.location, '/some/endpoint/id');
        assert.strictEqual(response.data, 'resource has been created');
        done();
      });
    });
  });

  describe('put', function () {
    it('should wait if a 2000ms latency is specified', function (done) {
      var start = new Date();

      this.timeout(3500);
      this.context.url = '/put/latency';
      this.context.method = 'put';

      createRequest(this.context, function (response) {
        var elapsed = new Date() - start;

        assert(elapsed > 1800 && elapsed < 3200);
        assert.strictEqual(response.data, 'updated');

        done();
      });
    });
  });

  describe('file use', function () {
    describe('response', function () {
      it('should handle file name interpolation', function (done) {
        this.context.url = '/file/dynamic/1';

        createRequest(this.context, function (response) {
          assert.strictEqual(response.data.trim(), 'endpoints-1.file');
          done();
        });
      });

      it('should handle file content interpolation', function (done) {
        this.context.url = '/file/dynamic/2';

        createRequest(this.context, function (response) {
          assert.strictEqual(response.data.trim(), 'endpoints-2.file');
          done();
        });
      });

      it('should handle fallback to body if specified response file cannot be found', function (done) {
        this.context.url = '/file/body/missingfile';

        createRequest(this.context, function (response) {
          assert.strictEqual(response.data, 'body contents!');
          done();
        });
      });

      it('should handle file response when file can be found', function (done) {
        this.context.url = '/file/body';

        createRequest(this.context, function (response) {
          assert.strictEqual(response.data.trim(), 'file contents!');
          done();
        });
      });
    });

    describe('request', function () {
      it('should handle fallback to post if specified request file cannot be found', function (done) {
        this.context.url = '/file/post/missingfile';
        this.context.method = 'post';
        this.context.post = 'post contents!';

        createRequest(this.context, function (response) {
          assert.strictEqual(response.statusCode, 200);
          done();
        });
      });

      it('should handle file request when file can be found', function (done) {
        this.context.url = '/file/post';
        this.context.method = 'post';
        this.context.post = 'file contents!';

        createRequest(this.context, function (response) {
          assert.strictEqual(response.statusCode, 200);
          done();
        });
      });
    });
  });

  describe('encoded special character query params', function () {
    it('should handle a query param that has been configured as decoded, sent as encoded', function (done) {
      this.context.url = '/post/decoded/character?q=%7B';
      this.context.method = 'post';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.data, 'decoded matched!');
        done();
      });
    });

    it('should handle a query param that has been configured as decoded, sent as decoded', function (done) {
      this.context.url = '/post/decoded/character?q={';
      this.context.method = 'post';

      createRequest(this.context, function (response) {
        assert.strictEqual(response.data, 'decoded matched!');
        done();
      });
    });
  });
});
