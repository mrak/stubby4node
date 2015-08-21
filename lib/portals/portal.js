'use strict';

var CLI = require('../console/cli');
var out = require('../console/out');
var http = require('http');

function Portal() {
  this.name = 'portal';
}

Portal.prototype.writeHead = function (response, statusCode, headers) {
  if (!response.headersSent) {
    response.writeHead(statusCode, headers);
  }
  return response;
};

Portal.prototype.received = function (request, response) {
  var date = new Date();
  var hours = ('0' + date.getHours()).slice(-2);
  var minutes = ('0' + date.getMinutes()).slice(-2);
  var seconds = ('0' + date.getSeconds()).slice(-2);

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
};

Portal.prototype.responded = function (status, url, message) {
  var fn;
  var date = new Date();
  var hours = ('0' + date.getHours()).slice(-2);
  var minutes = ('0' + date.getMinutes()).slice(-2);
  var seconds = ('0' + date.getSeconds()).slice(-2);

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
};

module.exports.Portal = Portal;
