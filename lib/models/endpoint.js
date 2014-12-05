'use strict';

var fs = require('fs');
var path = require('path');
var http = require('http');
var url = require('url');
var q = require('querystring');
var out = require('../console/out');

function Endpoint(endpoint, datadir) {
  if (endpoint == null) { endpoint = {}; }
  if (datadir == null) { datadir = process.cwd(); }

  Object.defineProperty(this, 'datadir', { value: datadir });

  this.request = purifyRequest(endpoint.request);
  this.response = purifyResponse(this, endpoint.response);
}

Endpoint.prototype.matches = function(request) {
  var matches = {};

  matches.url = matchRegex(this.request.url, request.url)
  if (!matches.url) { return null; }

  matches.headers = compareHashMaps(this.request.headers, request.headers)
  if (!matches.headers) { return null; }

  matches.query = compareHashMaps(this.request.query, request.query)
  if (!matches.query) { return null; }

  var file = null;
  if (this.request.file != null) {
    try {
      file = fs.readFileSync(path.resolve(this.datadir, this.request.file), 'utf8');
    } catch (e) {}
  }

  var post  = file || this.request.post;
  if (post && request.post) {
    matches.post = matchRegex(normalizeEOL(post), normalizeEOL(request.post))
    if (!matches.post) { return null; }
  }

  if (this.request.method instanceof Array) {
    var upperMethods = this.request.method.map(function(it) { return it.toUpperCase(); });
    if (upperMethods.indexOf(request.method) === -1) { return null; }
  } else {
    if (this.request.method.toUpperCase() !== request.method) { return null; }
  }

  return matches;
};

function record(me, urlToRecord) {
  var recording = {};
  var parsed = url.parse(urlToRecord);
  var options = {
    method: me.request.method == null ? 'GET' : me.request.method,
    hostname: parsed.hostname,
    headers: me.request.headers,
    port: parsed.port,
    path: parsed.pathname + '?'
  };

  if (parsed.query != null) {
    options.path += parsed.query + '&';
  }
  if (me.request.query != null) {
    options.path += q.stringify(me.request.query);
  }

  var recorder = http.request(options, function(res) {
    recording.status = res.statusCode;
    recording.headers = res.headers;
    recording.body = '';
    res.on('data', function(chunk) { return recording.body += chunk; });
    return res.on('end', function() { return out.notice('recorded ' + urlToRecord); });
  });

  recorder.on('error', function(e) { out.warn('error recording response ' + urlToRecord + ': ' + e.message); });
  recording.post = new Buffer(me.request.post == null ? 0 : me.request.post, 'utf8');

  if (me.request.file != null) {
    try { recording.post = fs.readFileSync(path.resolve(me.datadir, me.request.file)); }
    catch (e) {}
  }

  recorder.write(recording.post);
  recorder.end();

  return recording;
}

function normalizeEOL(string) {
  return string.replace(/\r\n/g, '\n').replace(/\s*$/, '');
}

function purifyRequest(incoming) {
  if (incoming == null) { incoming = {}; }

  var outgoing = {
    url: incoming.url,
    method: incoming.method == null ? 'GET' : incoming.method,
    headers: purifyHeaders(incoming.headers),
    query: incoming.query,
    file: incoming.file,
    post: incoming.post
  };

  outgoing.headers = purifyAuthorization(outgoing.headers);
  outgoing = pruneUndefined(outgoing);
  return outgoing;
}

function purifyResponse(me, incoming) {
  if (incoming == null) { incoming = []; }

  var outgoing = [];
  if (!(incoming instanceof Array)) { incoming = [incoming]; }
  if (incoming.length === 0) { incoming.push({}); }

  incoming.forEach(function (response) {
    if (typeof response === 'string') {
      outgoing.push(record(me, response));
    } else {
      outgoing.push(pruneUndefined({
        headers: purifyHeaders(response.headers),
        status: parseInt(response.status) || 200,
        latency: parseInt(response.latency) || undefined,
        file: response.file,
        body: purifyBody(response.body)
      }));
    }
  });

  return outgoing;
}

function purifyHeaders(incoming) {
  var outgoing = {};

  for (var prop in incoming) {
    outgoing[prop.toLowerCase()] = incoming[prop];
  }

  return outgoing;
}

function purifyAuthorization(headers) {
  if (headers == null || headers.authorization == null) { return headers; }

  var auth = headers.authorization || '';
  if (!/:/.test(auth)) { return headers; }

  headers.authorization = 'Basic ' + new Buffer(auth).toString('base64');
  return headers;
}

function purifyBody(body) {
  if (body == null) { body = ''; }

  if (typeof body === 'object') {
    return JSON.stringify(body);
  } else {
    return body;
  }
}

function pruneUndefined(incoming) {
  var outgoing = {};

  for (var key in incoming) {
    var value = incoming[key];
    if (value != null) { outgoing[key] = value; }
  }

  return outgoing;
}

function setFallbacks(endpoint) {
  if (endpoint.request.file != null) {
    try { endpoint.request.post = fs.readFileSync(endpoint.request.file, 'utf8'); }
    catch (e) {}
  }
  if (endpoint.response.file != null) {
    try { endpoint.response.body = fs.readFileSync(endpoint.response.file, 'utf8'); }
    catch (e) {}
  }
}

function compareHashMaps(configured, incoming) {
  if (configured == null) { configured = {}; }
  if (incoming == null) { incoming = {}; }

  var headers = {};
  for (var key in configured) {
    headers[key] = matchRegex(configured[key], incoming[key])
    if (!headers[key]) { return null; }
  }

  return headers;
}

function matchRegex(compileMe, testMe) {
  if (testMe == null) { testMe = ''; }
  return testMe.match(RegExp(compileMe, 'm'));
}

module.exports = Endpoint;
