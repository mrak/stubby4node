'use strict';

var Stubby = require('../src/main').Stubby;
var fs = require('fs');
var yaml = require('js-yaml');
var ce = require('cloneextend');
var endpointData = yaml.load((fs.readFileSync('test/data/e2e.yaml', 'utf8')).trim());
var waitsFor = require('./helpers/waits-for');
var assert = require('assert');
var createRequest = require('./helpers/create-request');

describe('End 2 End Admin Test Suite', function () {
  var sut;
  var port = 8889;

  function stopStubby(finish) {
    if (sut != null) {
      sut.stop(finish);
    } else {
      finish();
    }
  }

  beforeEach(function (done) {
    function finish() {
      sut = new Stubby();
      return sut.start({
        data: endpointData
      }, done);
    }

    this.context = {
      done: false,
      port: port
    };

    stopStubby(finish);
  });

  afterEach(function (done) {
    stopStubby(done);
  });

  it('should react to /ping', function (done) {
    var self = this;
    this.context.url = '/ping';

    createRequest(this.context);

    waitsFor(function () {
      return self.context.done;
    }, 'request to finish', 1000, function () {
      assert(self.context.response.data === 'pong');
      return done();
    });
  });

  it('should be able to retreive an endpoint through GET', function (done) {
    var self = this;
    var id = 3;
    var endpoint = ce.clone(endpointData[id - 1]);
    endpoint.id = id;
    this.context.url = '/' + id;
    this.context.method = 'get';

    createRequest(this.context);

    waitsFor(function () {
      return self.context.done;
    }, 'request to finish', 1000, function () {
      var prop, value;
      var returned = JSON.parse(self.context.response.data);
      var req = endpoint.req;

      for (prop in req) {
        if (!req.hasOwnProperty(prop)) { continue; }

        value = req[prop];
        assert(value === returned.request[prop]);
      }

      done();
    });
  });

  it('should be able to edit an endpoint through PUT', function (done) {
    var self = this;
    var id = 2;
    var endpoint = ce.clone(endpointData[id - 1]);
    this.context.url = '/' + id;
    endpoint.request.url = '/munchkin';
    this.context.method = 'put';
    this.context.post = JSON.stringify(endpoint);

    createRequest(this.context);

    waitsFor(function () {
      return self.context.done;
    }, 'put request to finish', 1000, function () {
      endpoint.id = id;
      self.context.done = false;
      self.context.method = 'get';

      createRequest(self.context);

      waitsFor(function () { return self.context.done; }, 'get request to finish', 1000, function () {
        var returned = JSON.parse(self.context.response.data);

        assert(returned.request.url === endpoint.request.url);

        done();
      });
    });
  });

  it('should be about to create an endpoint through POST', function (done) {
    var self = this;
    var endpoint = {
      request: {
        url: '/posted/endpoint'
      },
      response: {
        status: 200
      }
    };
    this.context.url = '/';
    this.context.method = 'post';
    this.context.post = JSON.stringify(endpoint);

    createRequest(this.context);

    waitsFor(function () {
      return self.context.done;
    }, 'post request to finish', 1000, function () {
      var id = self.context.response.headers.location.replace(/localhost:8889\/([0-9]+)/, '$1');

      assert(self.context.response.statusCode === 201);

      self.context = {
        port: port,
        done: false,
        url: '/' + id,
        method: 'get'
      };

      createRequest(self.context);

      waitsFor(function () {
        return self.context.done;
      }, 'get request to finish', 1000, function () {
        var returned = JSON.parse(self.context.response.data);

        assert(returned.request.url === endpoint.request.url);
        done();
      });
    });
  });

  it('should be about to delete an endpoint through DELETE', function (done) {
    var self = this;
    this.context.url = '/2';
    this.context.method = 'delete';

    createRequest(this.context);

    waitsFor(function () {
      return self.context.done;
    }, 'delete request to finish', 1000, function () {
      assert(self.context.response.statusCode === 204);

      self.context = {
        port: port,
        done: false,
        url: '/2',
        method: 'get'
      };

      createRequest(self.context);

      waitsFor(function () {
        return self.context.done;
      }, 'get request to finish', 1000, function () {
        assert(self.context.response.statusCode === 404);
        done();
      });
    });
  });
});
