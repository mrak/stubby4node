'use strict';

const Stubby = require('../src/main').Stubby;
const fs = require('fs');
const yaml = require('js-yaml');
const clone = require('../src/lib/clone');
const endpointData = yaml.load((fs.readFileSync('test/data/e2e.yaml', 'utf8')).trim());
const assert = require('assert');
const createRequest = require('./helpers/create-request');

describe('End 2 End Admin Test Suite', function () {
  let sut;
  const port = 8889;

  async function stopStubby () {
    if (sut != null) await sut.stop();
  }

  beforeEach(async function () {
    this.context = {
      done: false,
      port: port
    };

    await stopStubby();

    sut = new Stubby();
    await sut.start({ data: endpointData });
  });

  afterEach(stopStubby);

  it('should react to /ping', function (done) {
    this.context.url = '/ping';

    createRequest(this.context, function (response) {
      assert.strictEqual(response.data, 'pong');
      return done();
    });
  });

  it('should be able to retreive an endpoint through GET', function (done) {
    const id = 3;
    const endpoint = clone(endpointData[id - 1]);
    endpoint.id = id;
    this.context.url = '/' + id;
    this.context.method = 'get';

    createRequest(this.context, function (response) {
      let prop, value;
      const returned = JSON.parse(response.data);
      const req = endpoint.req;

      for (prop in req) {
        if (!Object.prototype.hasOwnProperty.call(req, prop)) { continue; }

        value = req[prop];
        assert.strictEqual(value, returned.request[prop]);
      }

      done();
    });
  });

  it('should be able to edit an endpoint through PUT', function (done) {
    const self = this;
    const id = 2;
    const endpoint = clone(endpointData[id - 1]);
    this.context.url = '/' + id;
    endpoint.request.url = '/munchkin';
    this.context.method = 'put';
    this.context.post = JSON.stringify(endpoint);

    createRequest(this.context, function () {
      endpoint.id = id;
      self.context.method = 'get';
      self.context.post = null;

      createRequest(self.context, function (response) {
        const returned = JSON.parse(response.data);

        assert.strictEqual(returned.request.url, endpoint.request.url);

        done();
      });
    });
  });

  it('should be about to create an endpoint through POST', function (done) {
    const self = this;
    const endpoint = {
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

    createRequest(this.context, function (response) {
      const id = response.headers.location.replace(/localhost:8889\/([0-9]+)/, '$1');

      assert.strictEqual(response.statusCode, 201);

      self.context = {
        port: port,
        done: false,
        url: '/' + id,
        method: 'get'
      };

      createRequest(self.context, function (response2) {
        const returned = JSON.parse(response2.data);

        assert.strictEqual(returned.request.url, endpoint.request.url);
        done();
      });
    });
  });

  it('should be about to delete an endpoint through DELETE', function (done) {
    const self = this;
    this.context.url = '/2';
    this.context.method = 'delete';

    createRequest(this.context, function (response) {
      assert.strictEqual(response.statusCode, 204);

      self.context = {
        port: port,
        done: false,
        url: '/2',
        method: 'get'
      };

      createRequest(self.context, function (response2) {
        assert.strictEqual(response2.statusCode, 404);
        done();
      });
    });
  });
});
