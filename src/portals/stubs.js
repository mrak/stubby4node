'use strict';

var Portal = require('./portal').Portal;
var qs = require('querystring');

function Stubs(endpoints) {
  Portal.call(this);
  this.server = this.server.bind(this);
  this.Endpoints = endpoints;
  this.name = '[stubs]';
}

Stubs.prototype = Object.create(Portal.prototype);
Stubs.prototype.constructor = Stubs;

Stubs.prototype.server = function (request, response) {
  var data = null;
  var self = this;

  request.on('data', function (chunk) {
    data = data != null ? data : '';
    data += chunk;

    return data;
  });

  request.on('end', function () {
    var criteria;

    self.received(request, response);

    criteria = {
      url: extractUrl(request.url),
      method: request.method,
      post: data,
      headers: request.headers,
      query: extractQuery(request.url)
    };

    function callback(err, endpointResponse) {
      if (err) {
        self.writeHead(response, 404, {});
        self.responded(404, request.url, 'is not a registered endpoint');
      } else {
        self.writeHead(response, endpointResponse.status, endpointResponse.headers);
        response.write(endpointResponse.body);
        self.responded(endpointResponse.status, request.url);
      }

      response.end();
    }

    try {
      self.Endpoints.find(criteria, callback);
    } catch (e) {
      response.statusCode = 500;
      self.responded(500, request.url, 'unexpectedly generated a server error: ' + e.message);
      response.end();
    }
  });
};

function extractUrl(url) {
  return url.replace(/(.*)\?.*/, '$1');
}

function extractQuery(url) {
  return qs.parse(url.replace(/^.*\?(.*)$/, '$1'));
}

module.exports.Stubs = Stubs;
