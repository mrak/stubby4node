'use strict';

var sut;
var Endpoints = require('../src/models/endpoints').Endpoints;
var assert = require('assert');
var bufferEqual = require('buffer-equal');

describe('Endpoints', function () {
  beforeEach(function () {
    sut = new Endpoints();
  });

  describe('operations', function () {
    var callback;

    beforeEach(function () {
      callback = this.sandbox.spy();
    });

    describe('create', function () {
      var data;

      beforeEach(function () {
        data = {
          request: {
            url: ''
          }
        };
      });

      it('should assign id to entered endpoint', function () {
        sut.create(data, callback);

        assert(sut.db[1] != null);
        assert(sut.db[2] == null);
      });

      it('should call callback', function () {
        sut.create(data, callback);

        assert(callback.calledOnce);
      });

      it('should assign ids to entered endpoints', function () {
        sut.create([data, data], callback);

        assert(sut.db[1] != null);
        assert(sut.db[2] != null);
        assert(sut.db[3] == null);
      });

      it('should call callback for each supplied endpoint', function () {
        sut.create([data, data], callback);

        assert(callback.calledTwice);
      });
    });

    describe('retrieve', function () {
      var id = 'any id';

      it('should call callback with null, row if operation returns a row', function () {
        var row = {
          request: {},
          response: {}
        };
        sut.db[id] = row;

        sut.retrieve(id, callback);

        assert(callback.args[0][0] === null);
        assert(callback.args[0][1]);
      });

      it('should call callback with error msg if operation does not find item', function () {
        sut.db = [];

        sut.retrieve(id, callback);

        assert(callback.calledWith("Endpoint with the given id doesn't exist."));
      });
    });

    describe('update', function () {
      var id = 'any id';
      var data = {
        request: {
          url: ''
        }
      };

      it('should call callback when database updates', function () {
        sut.db[id] = {};

        sut.update(id, data, callback);

        assert(callback.calledWithExactly());
      });

      it('should call callback with error msg if operation does not find item', function () {
        sut.update(id, data, callback);

        assert(callback.calledWith("Endpoint with the given id doesn't exist."));
      });
    });

    describe('delete', function () {
      var id = 'any id';

      it('should call callback when database updates', function () {
        sut.db[id] = {};

        sut.delete(id, callback);

        assert(callback.calledWithExactly());
      });

      it('should call callback with error message if operation does not find item', function () {
        sut.delete(id, callback);

        assert(callback.calledWith("Endpoint with the given id doesn't exist."));
      });
    });

    describe('gather', function () {
      it('should call callback with rows if operation returns some rows', function () {
        var data = [{}, {}];
        sut.db = data;

        sut.gather(callback);

        assert(callback.calledWith(null, data));
      });

      it('should call callback with empty array if operation does not find item', function () {
        sut.db = [];

        sut.gather(callback);

        assert(callback.calledWith(null, []));
      });
    });

    describe('find', function () {
      var data = {
        method: 'GET'
      };

      it('should call callback with null, row if operation returns a row', function () {
        sut.create({});
        sut.find(data, callback);

        assert(callback.args[0][0] === null);
        assert(callback.args[0][1]);
      });

      it('should call callback with error if operation does not find item', function () {
        sut.find(data, callback);

        assert(callback.calledWith("Endpoint with given request doesn't exist."));
      });

      it('should call callback after timeout if data response has a latency', function (done) {
        var start = new Date();

        sut.create({
          request: {},
          response: {
            latency: 1000
          }
        });
        sut.find(data, function () {
          var elapsed = new Date() - start;
          assert(elapsed > 900 && elapsed < 1100);
          done();
        });
      });

      describe('dynamic templating', function () {
        it('should replace all captures in body', function (done) {
          sut.create({
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

          sut.find(data, function (err, match) {
            assert(match.body === 'you posted "hello, there!" and "hello, there!"');
            done();
          });
        });

        it('should replace captures in a text file', function () {
          var expected = 'file contents!';
          sut.create({
            request: {
              url: '/',
              post: '.*'
            },
            response: {
              file: 'test/data/<% post[0] %>.file'
            }
          });
          data = {
            url: '/',
            method: 'GET',
            post: 'endpoints'
          };
          sut.find(data, callback);

          assert(callback.args[0][1].body.toString().trim() === expected);
        });

        it('should return binary data unmolested', function () {
          var body;
          var expected = new Buffer([0x80, 0x81, 0x82, 0xab, 0xcd, 0xef, 0x3c, 0x25, 0x20, 0x70, 0x6f, 0x73, 0x74, 0x5b, 0x30, 0x5d, 0x20, 0x25, 0x3e, 0xfe, 0xdc, 0xba, 0x82, 0x81, 0x80]);
          sut.create({
            request: {
              url: '/',
              post: '.*'
            },
            response: {
              file: 'test/data/<% post[0] %>.file'
            }
          });
          data = {
            url: '/',
            method: 'GET',
            post: 'binary'
          };
          sut.find(data, callback);
          body = callback.args[0][1].body;

          assert(body instanceof Buffer && bufferEqual(body, expected));
        });
      });

      describe('request json versus post or file', function () {
        it('should not match response if the request json does not match the incoming post', function () {
          var expected = 'Endpoint with given request doesn\'t exist.';

          sut.create({
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
          sut.find(data, callback);

          assert(callback.calledWith(expected));
        });

        it('should match response with json if json is supplied and neither post nor file are supplied', function () {
          var expected = {
            status: 200
          };
          sut.create({
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
          sut.find(data, callback);

          assert(callback.calledWith(null));
        });

        it('should match response with post if post is supplied', function () {
          var expected = {
            status: 200
          };
          sut.create({
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
          sut.find(data, callback);

          assert(callback.calledWith(null));
        });

        it('should match response with file if file is supplied', function () {
          var expected = {
            status: 200
          };
          sut.create({
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
          sut.find(data, callback);

          assert(callback.calledWith(null));
        });
      });

      describe('request post versus file', function () {
        it('should match response with post if file is not supplied', function () {
          var expected = {
            status: 200
          };
          sut.create({
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
          sut.find(data, callback);

          assert(callback.calledWith(null));
        });

        it('should match response with post file is supplied but cannot be found', function () {
          var expected = {
            status: 200
          };
          sut.create({
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
          sut.find(data, callback);

          assert(callback.calledWith(null));
        });

        it('should match response with file if file is supplied and exists', function () {
          var expected = {
            status: 200
          };
          sut.create({
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
          sut.find(data, callback);

          assert(callback.calledWith(null));
        });
      });

      describe('response body versus file', function () {
        it('should return response with body as content if file is not supplied', function () {
          var expected = 'the body!';
          sut.create({
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
          sut.find(data, callback);

          assert(callback.args[0][1].body.toString() === expected);
        });

        it('should return response with body as content if file is supplied but cannot be found', function () {
          var expected = 'the body!';
          sut.create({
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
          sut.find(data, callback);

          assert(callback.args[0][1].body.toString() === expected);
        });

        it('should return response with file as content if file is supplied and exists', function () {
          var expected = 'file contents!';
          sut.create({
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
          sut.find(data, callback);

          assert(callback.args[0][1].body.toString().trim() === expected);
        });
      });

      describe('method', function () {
        it('should return response even if cases match', function () {
          sut.create({
            request: {
              method: 'POST'
            },
            response: {}
          });
          data = {
            method: 'POST'
          };
          sut.find(data, callback);

          assert(callback.args[0][1]);
        });

        it('should return response even if cases do not match', function () {
          sut.create({
            request: {
              method: 'post'
            },
            response: {}
          });
          data = {
            method: 'POST'
          };
          sut.find(data, callback);

          assert(callback.args[0][1]);
        });

        it('should return response if method matches any of the defined', function () {
          sut.create({
            request: {
              method: ['post', 'put']
            },
            response: {}
          });
          data = {
            method: 'POST'
          };
          sut.find(data, callback);

          assert(callback.args[0][1]);
        });

        it('should call callback with error if none of the methods match', function () {
          sut.create({
            request: {
              method: ['post', 'put']
            },
            response: {}
          });
          data = {
            method: 'GET'
          };
          sut.find(data, callback);

          assert(callback.calledWith("Endpoint with given request doesn't exist."));
        });
      });

      describe('headers', function () {
        it('should return response if all headers of request match', function () {
          sut.create({
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
          sut.find(data, callback);

          assert(callback.args[0][1]);
        });

        it('should call callback with error if all headers of request dont match', function () {
          sut.create({
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
          sut.find(data, callback);

          assert(callback.calledWith("Endpoint with given request doesn't exist."));
        });
      });

      describe('query', function () {
        it('should return response if all query of request match', function () {
          sut.create({
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
          sut.find(data, callback);

          assert(callback.args[0][1]);
        });

        it('should call callback with error if all query of request dont match', function () {
          sut.create({
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
          sut.find(data, callback);

          assert(callback.calledWith("Endpoint with given request doesn't exist."));
        });
      });
    });
  });
});
