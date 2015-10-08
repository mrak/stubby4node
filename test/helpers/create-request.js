'use strict';

var http = require('http');
var qs = require('querystring');

module.exports = function (context, callback) {
  var request;
  var options = {
    port: context.port,
    method: context.method,
    path: context.url,
    headers: context.requestHeaders
  };

  context.done = false;

  if (context.query != null) {
    options.path += '?' + qs.stringify(context.query);
  }

  request = http.request(options, function (response) {
    var data = '';

    response.on('data', function (chunk) {
      data += chunk;
    });

    response.on('end', function () {
      response.data = data;
      callback(response);
    });
  });

  if (context.post != null) {
    request.write(context.post);
  }

  request.end();
  return request;
};
