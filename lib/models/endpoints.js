'use strict';

var ce = require('cloneextend');
var fs = require('fs');
var ejs = require('ejs');
var path = require('path');
var Endpoint = require('./endpoint');
var NOT_FOUND = "Endpoint with the given id doesn't exist.";
var NO_MATCH = "Endpoint with given request doesn't exist.";

function noop() {}

function Endpoints(data, callback, datadir) {
  if (callback == null) { callback = noop; }
  if (datadir == null) { datadir = process.cwd(); }

  this.datadir = datadir;
  this.db = {};
  this.lastId = 0;
  this.create(data, callback);
  this.sightings = {};
}

Endpoints.prototype.create = function(data, callback) {
  if (callback == null) { callback = noop; }

  var self = this;
  function insert(item) {
    item = new Endpoint(item, self.datadir);
    item.id = ++self.lastId;
    self.db[item.id] = item;
    self.sightings[item.id] = 0;
    callback(null, ce.clone(item));
  }

  if (data instanceof Array) {
    data.forEach(insert);
  } else if (data) {
    insert(data);
  }
};

Endpoints.prototype.retrieve = function(id, callback) {
  if (callback == null) { callback = noop; }

  if (!this.db[id]) { return callback(NOT_FOUND); }

  callback(null, ce.clone(this.db[id]));
};

Endpoints.prototype.update = function(id, data, callback) {
  if (callback == null) { callback = noop; }

  if (!this.db[id]) { return callback(NOT_FOUND); }

  var endpoint = new Endpoint(data, this.datadir);
  endpoint.id = id;
  this.db[endpoint.id] = endpoint;
  callback();
};

Endpoints.prototype["delete"] = function(id, callback) {
  if (callback == null) { callback = noop; }

  if (!this.db[id]) { return callback(NOT_FOUND); }

  delete this.db[id];
  callback();
};

Endpoints.prototype.gather = function(callback) {
  if (callback == null) { callback = noop; }

  var all = [];
  for (var id in this.db) {
    all.push(this.db[id]);
  }

  callback(null, ce.clone(all));
};

Endpoints.prototype.find = function(data, callback) {
  if (callback == null) { callback = noop; }

  for (var id in this.db) {
    var endpoint = this.db[id];
    var captures = endpoint.matches(data);

    if (!captures) { continue; }

    var matched = ce.clone(endpoint);
    return found.call(this, matched, captures, callback);
  }

  return callback(NO_MATCH);
};

function applyCaptures(obj, captures) {
  if (typeof obj === 'string') {
    return ejs.render(obj.toString().replace(/<%/g, '<%='), captures);
  }

  var results = [];
  for (var key in obj) {
    var value = obj[key];

    if (typeof value === 'string' || value instanceof Buffer) {
      results.push(obj[key] = ejs.render(value.toString().replace(/<%/g, '<%='), captures));
    } else {
      results.push(applyCaptures(value, captures));
    }
  }

  return results;
}

function found(endpoint, captures, callback) {
  var filename, _ref;
  var response = endpoint.response[this.sightings[endpoint.id]++ % endpoint.response.length];
  response.body = new Buffer((_ref = response.body) != null ? _ref : 0, 'utf8');
  response.headers['x-stubby-resource-id'] = endpoint.id;

  if (response.file != null) {
    filename = applyCaptures(response.file, captures);
    try { response.body = fs.readFileSync(path.resolve(this.datadir, filename)); }
    catch (e) {}
  }

  applyCaptures(response, captures);

  if (parseInt(response.latency)) {
    setTimeout((function() { callback(null, response); }), response.latency);
  } else {
    callback(null, response);
  }
}

module.exports.Endpoints = Endpoints;
