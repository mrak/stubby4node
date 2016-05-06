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

  Object.defineProperty(this, 'datadir', {value: datadir});

  this.request = purifyRequest(endpoint.request);
  this.response = purifyResponse(this, endpoint.response);
}

Endpoint.prototype.matches = function (request) {
  var file, post, json, upperMethods;
  var matches = {};

  matches.url = matchRegex(this.request.url, request.url);
  if (!matches.url) { return null; }

  matches.headers = compareHashMaps(this.request.headers, request.headers);
  if (!matches.headers) { return null; }

  matches.query = compareHashMaps(this.request.query, request.query);
  if (!matches.query) { return null; }

  file = null;
  if (this.request.file != null) {
    try {
      file = fs.readFileSync(path.resolve(this.datadir, this.request.file), 'utf8');
    } catch (e) { /* ignored */ }
  }

  post = file || this.request.post;
  if (post && request.post) {
    matches.post = matchRegex(normalizeEOL(post), normalizeEOL(request.post));
    if (!matches.post) { return null; }
  } else if (this.request.json && request.post) {
    try {
      json = JSON.parse(request.post);
      if (!compareObjects(this.request.json, json)) { return null; }
    } catch (e) {
      return null;
    }
  }

  if (this.request.method instanceof Array) {
    upperMethods = this.request.method.map(function (it) { return it.toUpperCase(); });
    if (upperMethods.indexOf(request.method) === -1) { return null; }
  } else if (this.request.method.toUpperCase() !== request.method) {
    return null;
  }

  return matches;
};

function record(me, urlToRecord) {
  var recorder;
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

  recorder = http.request(options, function (res) {
    recording.status = res.statusCode;
    recording.headers = res.headers;
    recording.body = '';
    res.on('data', function (chunk) { recording.body += chunk; });
    res.on('end', function () { out.notice('recorded ' + urlToRecord); });
  });

  recorder.on('error', function (e) { out.warn('error recording response ' + urlToRecord + ': ' + e.message); });
  recording.post = me.request.post == null ? new Buffer(0) : new Buffer(me.request.post, 'utf8');

  if (me.request.file != null) {
    try {
      recording.post = fs.readFileSync(path.resolve(me.datadir, me.request.file));
    } catch (e) { /* ignored */ }
  }

  recorder.write(recording.post);
  recorder.end();

  return recording;
}

function normalizeEOL(string) {
  return string.replace(/\r\n/g, '\n').replace(/\s*$/, '');
}

function purifyRequest(incoming) {
  var outgoing;

  if (incoming == null) { incoming = {}; }

  outgoing = {
    url: incoming.url,
    method: incoming.method == null ? 'GET' : incoming.method,
    headers: purifyHeaders(incoming.headers),
    query: incoming.query,
    file: incoming.file,
    post: incoming.post
  };

  if (incoming.json) {
    outgoing.json = JSON.parse(incoming.json);
  }

  outgoing.headers = purifyAuthorization(outgoing.headers);
  outgoing = pruneUndefined(outgoing);
  return outgoing;
}

function purifyResponse(me, incoming) {
  var outgoing = [];

  if (incoming == null) { incoming = []; }
  if (!(incoming instanceof Array)) { incoming = [incoming]; }
  if (incoming.length === 0) { incoming.push({}); }

  incoming.forEach(function (response) {
    if (typeof response === 'string') {
      outgoing.push(record(me, response));
    } else {
      outgoing.push(pruneUndefined({
        headers: purifyHeaders(response.headers),
        status: parseInt(response.status, 10) || 200,
        latency: parseInt(response.latency, 10) || null,
        file: response.file,
        body: purifyBody(response.body)
      }));
    }
  });

  return outgoing;
}

function purifyHeaders(incoming) {
  var prop;
  var outgoing = {};

  for (prop in incoming) {
    if (incoming.hasOwnProperty(prop)) {
      outgoing[prop.toLowerCase()] = incoming[prop];
    }
  }

  return outgoing;
}

function purifyAuthorization(headers) {
  var auth, userpass;

  if (headers == null || headers.authorization == null) { return headers; }

  auth = headers.authorization || '';

  if (/^Basic .+:.+$/.test(auth)) {
    userpass = auth.substr(6);
    headers.authorization = 'Basic ' + new Buffer(userpass).toString('base64');
  }

  return headers;
}

function purifyBody(body) {
  if (body == null) { body = ''; }

  if (typeof body === 'object') {
    return JSON.stringify(body);
  }

  return body;
}

function pruneUndefined(incoming) {
  var key, value;
  var outgoing = {};

  for (key in incoming) {
    if (!incoming.hasOwnProperty(key)) { continue; }

    value = incoming[key];
    if (value != null) { outgoing[key] = value; }
  }

  return outgoing;
}

function compareHashMaps(configured, incoming) {
  var key;
  var headers = {};
  if (configured == null) { configured = {}; }
  if (incoming == null) { incoming = {}; }

  for (key in configured) {
    if (!configured.hasOwnProperty(key)) { continue; }
    headers[key] = matchRegex(configured[key], incoming[key]);
    if (!headers[key]) { return null; }
  }

  return headers;
}

function compareObjects(configured, incoming) {
  var key;

  for (key in configured) {
    if (typeof configured[key] !== typeof incoming[key]) { return false; }

    if (typeof configured[key] === 'object') {
      if (!compareObjects(configured[key], incoming[key])) { return false; }
    } else if (configured[key] !== incoming[key]) { return false; }
  }

  return true;
}

function matchRegex(compileMe, testMe) {
  if (testMe == null) { testMe = ''; }
  return String(testMe).match(RegExp(compileMe, 'm'));
}

module.exports = Endpoint;
