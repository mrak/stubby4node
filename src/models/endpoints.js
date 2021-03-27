'use strict';

const fs = require('fs');
const ejs = require('ejs');
const path = require('path');
const isutf8 = require('isutf8');
const Endpoint = require('./endpoint');
const clone = require('../lib/clone');
const NOT_FOUND = "Endpoint with the given id doesn't exist.";
const NO_MATCH = "Endpoint with given request doesn't exist.";

class Endpoints {
  constructor (data, datadir) {
    if (datadir == null) { datadir = process.cwd(); }

    this.caseSensitiveHeaders = false;
    this.datadir = datadir;
    this.db = {};
    this.lastId = 0;
    this.create(data);
  }

  create (data) {
    const self = this;

    function insert (item) {
      item = new Endpoint(item, self.datadir, self.caseSensitiveHeaders);
      item.id = ++self.lastId;
      self.db[item.id] = item;
      return item;
    }

    if (data instanceof Array) {
      return data.map(insert);
    } else if (data) {
      return insert(data);
    }
  }

  retrieve (id) {
    if (!this.db[id]) throw new Error(NOT_FOUND);

    return clone(this.db[id]);
  }

  update (id, data) {
    if (!this.db[id]) throw new Error(NOT_FOUND);

    const endpoint = new Endpoint(data, this.datadir);
    endpoint.id = id;
    this.db[endpoint.id] = endpoint;
  }

  delete (id) {
    if (!this.db[id]) throw new Error(NOT_FOUND);

    delete this.db[id];
  }

  deleteAll () {
    delete this.db;
    this.db = {};
  }

  gather () {
    let id;
    const all = [];

    for (id in this.db) {
      if (Object.prototype.hasOwnProperty.call(this.db, id)) {
        all.push(this.db[id]);
      }
    }

    return clone(all);
  }

  find (data) {
    let id, endpoint, captures, matched;

    for (id in this.db) {
      if (!Object.prototype.hasOwnProperty.call(this.db, id)) { continue; }

      endpoint = this.db[id];
      captures = endpoint.matches(data);

      if (!captures) { continue; }

      endpoint.hits++;
      matched = clone(endpoint);
      return this.found(matched, captures);
    }

    throw new Error(NO_MATCH);
  }

  found (endpoint, captures) {
    let filename;
    const response = endpoint.response[endpoint.hits % endpoint.response.length];
    const _ref = response.body;

    response.body = _ref != null ? Buffer.from(_ref, 'utf8') : Buffer.alloc(0);
    response.headers['x-stubby-resource-id'] = endpoint.id;

    if (response.file != null) {
      filename = applyCaptures(response.file, captures);
      try {
        response.body = fs.readFileSync(path.resolve(this.datadir, filename));
      } catch (e) { /* ignored */ }
    }

    applyCaptures(response, captures);

    return response;
  }
}

function applyCaptures (obj, captures) {
  let key, value;
  if (typeof obj === 'string') {
    return ejs.render(obj.replace(/<%/g, '<%='), captures);
  }

  const results = [];
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
