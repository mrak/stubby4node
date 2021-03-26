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

  async goDELETE (request, response) {
    const id = this.getId(request.url);
    const self = this;

    if (id) {
      try {
        await this.endpoints.delete(id);
        self.noContent(response);
      } catch { self.notFound(response); }
    } else if (request.url === '/') {
      try {
        await this.endpoints.deleteAll();
        self.noContent(response);
      } catch { self.notFound(response); }
    } else {
      this.notSupported(response);
    }
  }

  async goGET (request, response) {
    const id = this.getId(request.url);

    if (id) {
      try {
        const endpoint = await this.endpoints.retrieve(id);
        this.ok(response, endpoint);
      } catch (err) { this.notFound(response); }
    } else {
      const data = await this.endpoints.gather();
      if (data.length === 0) { this.noContent(response); } else { this.ok(response, data); }
    }
  }

  async processPUT (id, data, response) {
    try { data = JSON.parse(data); } catch (e) { return this.badRequest(response); }

    const errors = this.contract(data);
    if (errors) { return this.badRequest(response, errors); }

    try {
      await this.endpoints.update(id, data);
      this.noContent(response);
    } catch (_) { this.notFound(response); }
  }

  async processPOST (data, response, request) {
    const self = this;

    try { data = JSON.parse(data); } catch (e) { return this.badRequest(response); }

    const errors = this.contract(data);
    if (errors) { return this.badRequest(response, errors); }

    function callback (endpoint) {
      self.created(response, request, endpoint.id);
    }

    await this.endpoints.create(data, callback);
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
