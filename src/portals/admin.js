'use strict';

const contract = require('../models/contract');
const Portal = require('./portal').Portal;
const ns = require('node-static');
const path = require('path');
const status = new ns.Server(path.resolve(__dirname, '../../webroot'));
const urlPattern = /^\/([1-9][0-9]*)?$/;

class Admin extends Portal {
  constructor (endpoints) {
    super();
    this.server = this.server.bind(this);
    this.endpoints = endpoints;
    this.contract = contract;
    this.name = '[admin]';
  }

  goPong (response) {
    this.writeHead(response, 200, {
      'Content-Type': 'text/plain'
    });

    response.end('pong');
  }

  goPUT (request, response) {
    const id = this.getId(request.url);
    let data = '';
    const self = this;

    if (!id) { return this.notSupported(response); }

    request.on('data', function (chunk) { data += chunk; });
    request.on('end', function () { self.processPUT(id, data, response); });
  }

  goPOST (request, response) {
    const id = this.getId(request.url);
    let data = '';
    const self = this;

    if (id) { return this.notSupported(response); }

    request.on('data', function (chunk) { data += chunk; });
    request.on('end', function () { self.processPOST(data, response, request); });
  }

  goDELETE (request, response) {
    const id = this.getId(request.url);
    const self = this;

    function callback (err) {
      if (err) { self.notFound(response); } else { self.noContent(response); }
    }

    if (id) {
      this.endpoints.delete(id, callback);
    } else if (request.url === '/') {
      this.endpoints.deleteAll(callback);
    } else {
      this.notSupported(response);
    }
  }

  goGET (request, response) {
    let callback;
    const id = this.getId(request.url);
    const self = this;

    if (id) {
      callback = function (err, endpoint) {
        if (err) { self.notFound(response); } else { self.ok(response, endpoint); }
      };

      return this.endpoints.retrieve(id, callback);
    }

    callback = function (_, data) {
      if (data.length === 0) { self.noContent(response); } else { self.ok(response, data); }
    };

    return this.endpoints.gather(callback);
  }

  processPUT (id, data, response) {
    const self = this;

    try { data = JSON.parse(data); } catch (e) { return this.badRequest(response); }

    const errors = this.contract(data);
    if (errors) { return this.badRequest(response, errors); }

    function callback (err) {
      if (err) { self.notFound(response); } else { self.noContent(response); }
    }

    this.endpoints.update(id, data, callback);
  }

  processPOST (data, response, request) {
    const self = this;

    try { data = JSON.parse(data); } catch (e) { return this.badRequest(response); }

    const errors = this.contract(data);
    if (errors) { return this.badRequest(response, errors); }
    function callback (_, endpoint) {
      self.created(response, request, endpoint.id);
    }

    this.endpoints.create(data, callback);
  }

  ok (response, result) {
    this.writeHead(response, 200, {
      'Content-Type': 'application/json'
    });

    if (result != null) { return response.end(JSON.stringify(result)); }
    return response.end();
  }

  created (response, request, id) {
    this.writeHead(response, 201, {
      Location: request.headers.host + '/' + id
    });

    response.end();
  }

  noContent (response) {
    response.statusCode = 204;
    response.end();
  }

  badRequest (response, errors) {
    this.writeHead(response, 400, {
      'Content-Type': 'application/json'
    });

    response.end(JSON.stringify(errors));
  }

  notSupported (response) {
    response.statusCode = 405;
    response.end();
  }

  notFound (response) {
    this.writeHead(response, 404, {
      'Content-Type': 'text/plain'
    });

    response.end();
  }

  saveError (response) {
    this.writeHead(response, 422, {
      'Content-Type': 'text/plain'
    });

    response.end();
  }

  serverError (response) {
    this.writeHead(response, 500, {
      'Content-Type': 'text/plain'
    });

    response.end();
  }

  urlValid (url) {
    return url.match(urlPattern) != null;
  }

  getId (url) {
    return url.replace(urlPattern, '$1');
  }

  server (request, response) {
    const self = this;

    this.received(request, response);

    response.on('finish', function () {
      self.responded(response.statusCode, request.url);
    });

    if (request.url === '/ping') { return this.goPong(response); }
    if (/^\/(status|js|css)(\/.*)?$/.test(request.url)) { return status.serve(request, response); }

    if (this.urlValid(request.url)) {
      switch (request.method.toUpperCase()) {
        case 'PUT':
          return this.goPUT(request, response);
        case 'POST':
          return this.goPOST(request, response);
        case 'DELETE':
          return this.goDELETE(request, response);
        case 'GET':
          return this.goGET(request, response);
        default:
          return this.notSupported(response);
      }
    } else {
      return this.notFound(response);
    }
  }
}

module.exports.Admin = Admin;
