'use strict';

const Portal = require('./portal').Portal;
const qs = require('querystring');

class Stubs extends Portal {
  constructor (endpoints) {
    super();
    this.server = this.server.bind(this);
    this.Endpoints = endpoints;
    this.name = '[stubs]';
  }

  server (request, response) {
    let data = null;
    const self = this;

    request.on('data', function (chunk) {
      data = data != null ? data : '';
      data += chunk;

      return data;
    });

    request.on('end', function () {
      self.received(request, response);

      const criteria = {
        url: extractUrl(request.url),
        method: request.method,
        post: data,
        headers: request.headers,
        query: extractQuery(request.url)
      };

      function callback (err, endpointResponse) {
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
  }
}

function extractUrl (url) {
  return url.replace(/(.*)\?.*/, '$1');
}

function extractQuery (url) {
  return qs.parse(url.replace(/^.*\?(.*)$/, '$1'));
}

module.exports.Stubs = Stubs;
