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

    request.on('data', function (chunk) {
      data = data != null ? data : '';
      data += chunk;

      return data;
    });

    request.on('end', () => {
      this.received(request, response);

      const criteria = {
        url: request.url.replace(/(.*)\?.*/, '$1'),
        method: request.method,
        post: data,
        headers: request.headers,
        query: qs.parse(request.url.replace(/^.*\?(.*)$/, '$1'))
      };

      try {
        const endpointResponse = this.Endpoints.find(criteria);
        const finalize = () => {
          this.writeHead(response, endpointResponse.status, endpointResponse.headers);
          response.write(endpointResponse.body);
          this.responded(endpointResponse.status, request.url);
          response.end();
        };
        if (parseInt(endpointResponse.latency, 10)) setTimeout(finalize, endpointResponse.latency);
        else finalize();
      } catch (e) {
        this.writeHead(response, 404, {});
        this.responded(404, request.url, 'is not a registered endpoint');
        // response.statusCode = 500;
        // self.responded(500, request.url, 'unexpectedly generated a server error: ' + e.message);
        response.end();
      }
    });
  }
}

module.exports.Stubs = Stubs;
