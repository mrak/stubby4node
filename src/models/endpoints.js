'use strict';

var fs = require('fs');
var ejs = require('ejs');
var path = require('path');
var isutf8 = require('isutf8');
var Endpoint = require('./endpoint');
var clone = require('../lib/clone');
const out = require('../console/out');
var NOT_FOUND = "Endpoint with the given id doesn't exist.";
var NO_MATCH = "Endpoint with given request doesn't exist.";

function noop () {}

function Endpoints (data, callback, datadir) {
  if (callback == null) { callback = noop; }
  if (datadir == null) { datadir = process.cwd(); }

  this.datadir = datadir;
  this.db = {};
  this.lastId = 0;
  this.create(data, callback);
}

Endpoints.prototype.create = function (data, callback) {
  var self = this;

  if (callback == null) { callback = noop; }

  function insert (item) {
    item = new Endpoint(item, self.datadir);
    item.id = ++self.lastId;
    self.db[item.id] = item;
    callback(null, clone(item));
  }

  if (data instanceof Array) {
    data.forEach(insert);
  } else if (data) {
    insert(data);
  }
};

Endpoints.prototype.retrieve = function (id, callback) {
  if (callback == null) { callback = noop; }

  if (!this.db[id]) { return callback(NOT_FOUND); }

  callback(null, clone(this.db[id]));
};

Endpoints.prototype.update = function (id, data, callback) {
  var endpoint;

  if (callback == null) { callback = noop; }

  if (!this.db[id]) { return callback(NOT_FOUND); }

  endpoint = new Endpoint(data, this.datadir);
  endpoint.id = id;
  this.db[endpoint.id] = endpoint;
  callback();
};

Endpoints.prototype.delete = function (id, callback) {
  if (callback == null) { callback = noop; }

  if (!this.db[id]) { return callback(NOT_FOUND); }

  delete this.db[id];
  callback();
};

Endpoints.prototype.gather = function (callback) {
  var id;
  var all = [];

  if (callback == null) { callback = noop; }

  for (id in this.db) {
    if (Object.prototype.hasOwnProperty.call(this.db, id)) {
      all.push(this.db[id]);
    }
  }

  callback(null, clone(all));
};

Endpoints.prototype.find = function (data, callback) {
  var id, endpoint, captures, matched;
  if (callback == null) { callback = noop; }

  out.debugHeader('Incoming request');
  out.debug(data);
  for (id in this.db) {
    if (!Object.prototype.hasOwnProperty.call(this.db, id)) { continue; }

    endpoint = this.db[id];
    captures = endpoint.matches(data);

    if (!captures) { continue; }

    endpoint.hits++;
    matched = clone(endpoint);
    return this.found(matched, captures, callback);
  }

  return callback(NO_MATCH);
};

Endpoints.prototype.found = function (endpoint, captures, callback) {
  var filename;
  var response = endpoint.response[endpoint.hits % endpoint.response.length];
  var _ref = response.body;

  response.body = _ref != null ? Buffer.from(_ref, 'utf8') : Buffer.alloc(0);
  response.headers['x-stubby-resource-id'] = endpoint.id;

  if (response.file != null) {
    filename = applyCaptures(response.file, captures);
    try {
      response.body = fs.readFileSync(path.resolve(this.datadir, filename));
    } catch (e) { /* ignored */ }
  }

  applyCaptures(response, captures);

  out.debugHeader('Outgoing response');
  out.debug(response);
  if (parseInt(response.latency, 10)) {
    setTimeout(function () { callback(null, response); }, response.latency);
  } else {
    callback(null, response);
  }
};

function applyCaptures (obj, captures) {
  var results, key, value;
  if (typeof obj === 'string') {
    return ejs.render(obj.replace(/<%/g, '<%='), captures);
  }

  results = [];
  for (key in obj) {
    if (!Object.prototype.hasOwnProperty.call(obj, key)) { continue; }

    value = obj[key];

    // if a buffer looks like valid UTF-8, treat it as a string for capture replacement:
    if (value instanceof Buffer && isutf8(value)) {
      value = value.toString();
    }

    if (typeof value === 'string') {
      results.push(obj[key] = ejs.render(value.replace(/<%/g, '<%='), captures));
    } else {
      results.push(applyCaptures(value, captures));
    }
  }

  return results;
}

module.exports.Endpoints = Endpoints;
