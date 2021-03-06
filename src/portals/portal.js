'use strict';

const CLI = require('../console/cli');
const out = require('../console/out');
const http = require('http');

class Portal {
  constructor () { this.name = 'portal'; }

  writeHead (response, statusCode, headers) {
    if (!response.headersSent) {
      response.writeHead(statusCode, headers);
    }
    return response;
  }

  received (request, response) {
    const date = new Date();
    const hours = ('0' + date.getHours()).slice(-2);
    const minutes = ('0' + date.getMinutes()).slice(-2);
    const seconds = ('0' + date.getSeconds()).slice(-2);

    out.incoming(hours + ':' + minutes + ':' + seconds + ' -> ' + request.method + ' ' + this.name + request.url);
    response.setHeader('Server', 'stubby/' + CLI.version() + ' node/' + process.version + ' (' + process.platform + ' ' + process.arch + ')');

    if (request.headers.origin != null) {
      response.setHeader('Access-Control-Allow-Origin', request.headers.origin);
      response.setHeader('Access-Control-Allow-Credentials', true);

      if (request.headers['access-control-request-headers'] != null) {
        response.setHeader('Access-Control-Allow-Headers', request.headers['access-control-request-headers']);
      }

      if (request.headers['access-control-request-method'] != null) {
        response.setHeader('Access-Control-Allow-Methods', request.headers['access-control-request-method']);
      }

      if (request.method === 'OPTIONS') {
        this.writeHead(response, 200, response.headers);
        response.end();
      }
    }

    return response;
  }

  responded (status, url, message) {
    let fn;
    const date = new Date();
    const hours = ('0' + date.getHours()).slice(-2);
    const minutes = ('0' + date.getMinutes()).slice(-2);
    const seconds = ('0' + date.getSeconds()).slice(-2);

    if (url == null) { url = ''; }
    if (message == null) { message = http.STATUS_CODES[status]; }

    switch (true) {
      case status >= 400 && status < 600:
        fn = 'error';
        break;
      case status >= 300:
        fn = 'warn';
        break;
      case status >= 200:
        fn = 'ok';
        break;
      case status >= 100:
        fn = 'info';
        break;
      default:
        fn = 'log';
    }

    out[fn](hours + ':' + minutes + ':' + seconds + ' <- ' + status + ' ' + this.name + url + ' ' + message);
  }
}

module.exports.Portal = Portal;
