'use strict';

var contract = require('../models/contract');
var Portal = require('./portal').Portal;
var ns = require('node-static');
var path = require('path');
var status = new ns.Server(path.resolve(__dirname, '../../webroot'));

function Admin(endpoints) {
  Portal.call(this);
  this.server = this.server.bind(this);
  this.endpoints = endpoints;
  this.contract = contract;
  this.name = '[admin]';
}

Admin.prototype = Object.create(Portal.prototype);
Admin.prototype.constructor = Admin;

Admin.prototype.urlPattern = /^\/([1-9][0-9]*)?$/;

Admin.prototype.goPong = function (response) {
  this.writeHead(response, 200, {
    'Content-Type': 'text/plain'
  });

  response.end('pong');
};

Admin.prototype.goPUT = function (request, response) {
  var id = this.getId(request.url);
  var data = '';
  var self = this;

  if (!id) { return this.notSupported(response); }

  request.on('data', function (chunk) { data += chunk; });
  request.on('end', function () { self.processPUT(id, data, response); });
};

Admin.prototype.goPOST = function (request, response) {
  var id = this.getId(request.url);
  var data = '';
  var self = this;

  if (id) { return this.notSupported(response); }

  request.on('data', function (chunk) { data += chunk; });
  request.on('end', function () { self.processPOST(data, response, request); });
};

Admin.prototype.goDELETE = function (request, response) {
  var id = this.getId(request.url);
  var self = this;

  if (!id) { return this.notSupported(response); }

  function callback(err) {
    if (err) { self.notFound(response); } else { self.noContent(response); }
  }

  this.endpoints.delete(id, callback);
};

Admin.prototype.goGET = function (request, response) {
  var callback;
  var id = this.getId(request.url);
  var self = this;

  if (id) {
    callback = function (err, endpoint) {
      if (err) { self.notFound(response); } else { self.ok(response, endpoint); }
    };

    return this.endpoints.retrieve(id, callback);
  }

  callback = function (err, data) {
    if (data.length === 0) { self.noContent(response); } else { self.ok(response, data); }
  };

  return this.endpoints.gather(callback);
};

Admin.prototype.processPUT = function (id, data, response) {
  var errors;
  var self = this;

  try { data = JSON.parse(data); } catch (e) { return this.badRequest(response); }

  errors = this.contract(data);
  if (errors) { return this.badRequest(response, errors); }

  function callback(err) {
    if (err) { self.notFound(response); } else { self.noContent(response); }
  }

  this.endpoints.update(id, data, callback);
};

Admin.prototype.processPOST = function (data, response, request) {
  var errors;
  var self = this;

  try { data = JSON.parse(data); } catch (e) { return this.badRequest(response); }

  errors = this.contract(data);
  if (errors) { return this.badRequest(response, errors); }
  function callback(err, endpoint) {
    self.created(response, request, endpoint.id);
  }

  this.endpoints.create(data, callback);
};

Admin.prototype.ok = function (response, result) {
  this.writeHead(response, 200, {
    'Content-Type': 'application/json'
  });

  if (result != null) { return response.end(JSON.stringify(result)); }
  return response.end();
};

Admin.prototype.created = function (response, request, id) {
  this.writeHead(response, 201, {
    Location: request.headers.host + '/' + id
  });

  response.end();
};

Admin.prototype.noContent = function (response) {
  response.statusCode = 204;
  response.end();
};

Admin.prototype.badRequest = function (response, errors) {
  this.writeHead(response, 400, {
    'Content-Type': 'application/json'
  });

  response.end(JSON.stringify(errors));
};

Admin.prototype.notSupported = function (response) {
  response.statusCode = 405;
  response.end();
};

Admin.prototype.notFound = function (response) {
  this.writeHead(response, 404, {
    'Content-Type': 'text/plain'
  });

  response.end();
};

Admin.prototype.saveError = function (response) {
  this.writeHead(response, 422, {
    'Content-Type': 'text/plain'
  });

  response.end();
};

Admin.prototype.serverError = function (response) {
  this.writeHead(response, 500, {
    'Content-Type': 'text/plain'
  });

  response.end();
};

Admin.prototype.urlValid = function (url) {
  return url.match(this.urlPattern) != null;
};

Admin.prototype.getId = function (url) {
  return url.replace(this.urlPattern, '$1');
};

Admin.prototype.server = function (request, response) {
  var self = this;

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
};

module.exports.Admin = Admin;
