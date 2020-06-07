'use strict';

var fs = require('fs');
var path = require('path');
var http = require('http');
var q = require('querystring');
var out = require('../console/out');

function Endpoint (endpoint, datadir) {
  if (endpoint == null) { endpoint = {}; }
  if (datadir == null) { datadir = process.cwd(); }

  Object.defineProperty(this, 'datadir', { value: datadir });
  out.debug('datadir: ' + this.datadir, 'Datadir for files specified in endpoint configuration');

  this.request = purifyRequest(endpoint.request);
  this.response = purifyResponse(this, endpoint.response);
  this.hits = 0;
}

Endpoint.prototype.matches = function (request) {
  var file, post, json, upperMethods;
  var matches = {};

  out.debugHeader('Endpoint matches');
  out.debug(this);
  out.debugHeader('URL match');
  matches.url = matchRegex(this.request.url, request.url);
  out.debug(!(!matches.url), 'URL matches');
  if (!matches.url) { return null; }

  out.debugHeader('Header match');
  matches.headers = compareHashMaps(this.request.headers, request.headers);
  out.debug(!(!matches.headers), 'Header matches');
  if (!matches.headers) { return null; }

  out.debugHeader('Query match');
  matches.query = compareHashMaps(this.request.query, request.query);
  out.debug(!(!matches.query), 'Query matches');
  if (!matches.query) { return null; }

  file = null;
  if (this.request.file != null) {
    try {
      file = fs.readFileSync(path.resolve(this.datadir, this.request.file), 'utf8');
    } catch (e) {
      out.debug('Failed to read ' + this.request.file + ': ' + e);
    }
  }

  out.debugHeader('Post match');
  post = file || this.request.post;
  if (post && request.post) {
    matches.post = matchRegex(normalizeEOL(post), normalizeEOL(request.post));
    out.debug(!(!matches.post), 'Post matches');
    if (!matches.post) { return null; }
  } else if (this.request.json && request.post) {
    try {
      json = JSON.parse(request.post);
      matches.post = compareObjects(this.request.json, json);
      out.debug(!(!matches.post), 'Post matches');
      if (!matches.post) { return null; }
    } catch (e) {
      return null;
    }
  } else if (this.request.form && request.post) {
    matches.post = compareHashMaps(this.request.form, q.decode(request.post));
    out.debug(!(!matches.post), 'Post matches');
    if (!matches.post) { return null; }
  }

  out.debugHeader('Method match');
  if (this.request.method instanceof Array) {
    upperMethods = this.request.method.map(function (it) { return it.toUpperCase(); });
    if (upperMethods.indexOf(request.method) === -1) {
      out.debug(request.method + ' not present in ' + upperMethods);
      return null;
    }
  } else if (this.request.method.toUpperCase() !== request.method) {
    out.debug(request.method + ' not equal to ' + this.request.method);
    return null;
  } else {
    out.debug('Method matches');
  }

  out.debug(matches, 'Endpoint matches');
  return matches;
};

function record (me, urlToRecord) {
  var recorder;
  var recording = {};
  var parsed = new URL(urlToRecord);
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
  recording.post = me.request.post == null ? Buffer.alloc(0) : Buffer.from(me.request.post, 'utf8');

  if (me.request.file != null) {
    try {
      recording.post = fs.readFileSync(path.resolve(me.datadir, me.request.file));
    } catch (e) { /* ignored */ }
  }

  recorder.write(recording.post);
  recorder.end();

  return recording;
}

function normalizeEOL (string) {
  return string.replace(/\r\n/g, '\n').replace(/\s*$/, '');
}

function purifyRequest (incoming) {
  var outgoing;

  if (incoming == null) { incoming = {}; }

  out.debugHeader('Request');
  out.debug(incoming, 'Configured request');
  outgoing = {
    url: incoming.url,
    method: incoming.method == null ? 'GET' : incoming.method,
    headers: purifyHeaders(incoming.headers),
    query: incoming.query,
    file: incoming.file,
    post: incoming.post,
    form: incoming.form
  };

  if (incoming.json) {
    outgoing.json = JSON.parse(incoming.json);
  }

  outgoing.headers = purifyAuthorization(outgoing.headers);
  outgoing = pruneUndefined(outgoing);
  out.debug(outgoing, 'Purified request');
  return outgoing;
}

function purifyResponse (me, incoming) {
  var outgoing = [];

  out.debugHeader('Response');
  if (incoming == null) { incoming = []; }
  if (!(incoming instanceof Array)) { incoming = [incoming]; }
  if (incoming.length === 0) { incoming.push({}); }

  incoming.forEach(function (response) {
    out.debug(incoming, 'Configured response');
    if (typeof response === 'string') {
      const outgoingResponse = record(me, response);
      out.debug(outgoingResponse, 'Purified response');
      outgoing.push(outgoingResponse);
    } else {
      const outgoingResponse = pruneUndefined({
        headers: purifyHeaders(response.headers),
        status: parseInt(response.status, 10) || 200,
        latency: parseInt(response.latency, 10) || null,
        file: response.file,
        body: purifyBody(response.body)
      });
      out.debug(outgoingResponse, 'Purified response');
      outgoing.push(outgoingResponse);
    }
  });

  return outgoing;
}

function purifyHeaders (incoming) {
  var prop;
  var outgoing = {};

  for (prop in incoming) {
    if (Object.prototype.hasOwnProperty.call(incoming, prop)) {
      outgoing[prop.toLowerCase()] = incoming[prop];
    }
  }

  return outgoing;
}

function purifyAuthorization (headers) {
  var auth, userpass;

  if (headers == null || headers.authorization == null) { return headers; }

  auth = headers.authorization || '';

  if (/^Basic .+:.+$/.test(auth)) {
    userpass = auth.substr(6);
    headers.authorization = 'Basic ' + Buffer.from(userpass).toString('base64');
  }

  return headers;
}

function purifyBody (body) {
  if (body == null) { body = ''; }

  if (typeof body === 'object') {
    return JSON.stringify(body);
  }

  return body;
}

function pruneUndefined (incoming) {
  var key, value;
  var outgoing = {};

  for (key in incoming) {
    if (!Object.prototype.hasOwnProperty.call(incoming, key)) { continue; }

    value = incoming[key];
    if (value != null) { outgoing[key] = value; }
  }

  return outgoing;
}

function compareHashMaps (configured, incoming) {
  var key;
  var headers = {};
  if (configured == null) { configured = {}; }
  if (incoming == null) { incoming = {}; }

  for (key in configured) {
    if (!Object.prototype.hasOwnProperty.call(configured, key)) { continue; }
    headers[key] = matchRegex(configured[key], incoming[key]);
    out.debug('Header ' + key + ' matches: ' + !(!headers[key]));
    if (!headers[key]) { return null; }
  }

  return headers;
}

function compareObjects (configured, incoming) {
  var key;

  out.debug(configured, 'Configured object');
  out.debug(incoming, 'Incoming object');
  for (key in configured) {
    if (typeof configured[key] !== typeof incoming[key]) {
      out.debug('Types are different for ' + key);
      return false;
    }

    if (typeof configured[key] === 'object') {
      if (!compareObjects(configured[key], incoming[key])) {
        out.debug('Types are different for ' + key);
        return false;
      }
    } else if (configured[key] !== incoming[key]) {
      out.debug(key + ' does not match');
      return false;
    }
  }

  out.debug('Objects match');
  return true;
}

function matchRegex (compileMe, testMe) {
  if (testMe == null) { testMe = ''; }
  out.debug('Regex: ' + compileMe);
  out.debug('String: ' + testMe);
  return String(testMe).match(RegExp(compileMe, 'm'));
}

module.exports = Endpoint;
