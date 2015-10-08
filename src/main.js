'use strict';

var Admin = require('./portals/admin').Admin;
var Stubs = require('./portals/stubs').Stubs;
var Endpoints = require('./models/endpoints').Endpoints;
var Watcher = require('./console/watch');
var async = require('async');
var CLI = require('./console/cli');
var out = require('./console/out');
var http = require('http');
var https = require('https');
var contract = require('./models/contract');
var couldNotSave = "The supplied endpoint data couldn't be saved";

function noop() {}

function onListening(portal, port, protocol, location) {
  if (protocol == null) { protocol = 'http'; }
  out.status(portal + ' portal running at ' + protocol + '://' + location + ':' + port);
}

function onError(err, port, location) {
  var msg;

  switch (err.code) {
    case 'EACCES':
      msg = 'Permission denied for use of port ' + port + '. Exiting...';
      break;
    case 'EADDRINUSE':
      msg = 'Port ' + port + ' is already in use! Exiting...';
      break;
    case 'EADDRNOTAVAIL':
      msg = 'Host "' + location + '" is not available! Exiting...';
      break;
    default:
      msg = err.message + '. Exiting...';
  }
  out.error(msg);
  console.dir(err); // eslint-disable-line
  process.exit();
}

function onEndpointLoaded(err, endpoint) {
  out.notice('Loaded: ' + endpoint.request.method + ' ' + endpoint.request.url);
}

function setupStartOptions(options, callback) {
  var defaults, key;

  options = options == null ? {} : options;
  callback = callback == null ? noop : callback;

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  if (options.mute == null) { options.mute = true; }

  defaults = CLI.getArgs([]);
  for (key in defaults) {
    if (options[key] == null) {
      options[key] = defaults[key];
    }
  }

  out.mute = options.mute;
  return [options, callback];
}

function createHttpsOptions(options) {
  var httpsOptions = options._httpsOptions || {};

  if (options.key && options.cert) {
    httpsOptions.key = options.key;
    httpsOptions.cert = options.cert;
  } else if (options.pfx) {
    httpsOptions.pfx = options.pfx;
  }

  return httpsOptions;
}

function Stubby() {
  this.endpoints = new Endpoints();
  this.stubsPortal = null;
  this.tlsPortal = null;
  this.adminPortal = null;
}

Stubby.prototype.start = function (o, cb) {
  var oc = setupStartOptions(o, cb);
  var options = oc[0];
  var callback = oc[1];
  var self = this;

  this.stop(function () {
    var errors = contract(options.data);

    if (errors) { return callback(errors); }
    if (options.datadir != null) { self.endpoints.datadir = options.datadir; }

    self.endpoints.create(options.data, onEndpointLoaded);

    self.tlsPortal = https.createServer(createHttpsOptions(options), new Stubs(self.endpoints).server);
    self.tlsPortal.on('listening', function () { onListening('Stubs', options.tls, 'https', options.location); });
    self.tlsPortal.on('error', function (err) { onError(err, options.tls, options.location); });
    self.tlsPortal.listen(options.tls, options.location);

    self.stubsPortal = http.createServer(new Stubs(self.endpoints).server);
    self.stubsPortal.on('listening', function () { onListening('Stubs', options.stubs, 'http', options.location); });
    self.stubsPortal.on('error', function (err) { onError(err, options.stubs, options.location); });
    self.stubsPortal.listen(options.stubs, options.location);

    self.adminPortal = http.createServer(new Admin(self.endpoints).server);
    self.adminPortal.on('listening', function () { onListening('Admin', options.admin, 'http', options.location); });
    self.adminPortal.on('error', function (err) { onError(err, options.admin, options.location); });
    self.adminPortal.listen(options.admin, options.location);

    if (options.watch) { self.watcher = new Watcher(self.endpoints, options.watch); }

    out.info('\nQuit: ctrl-c\n');
    callback();
  });
};

Stubby.prototype.stop = function (callback) {
  var self = this;

  if (callback == null) { callback = noop; }

  setTimeout(function () {
    if (self.watcher != null) { self.watcher.deactivate(); }

    async.parallel({
      closeAdmin: function (cb) {
        if (self.adminPortal && self.adminPortal.address()) { self.adminPortal.close(cb); } else { cb(); }
      },
      closeStubs: function (cb) {
        if (self.stubsPortal && self.stubsPortal.address()) { self.stubsPortal.close(cb); } else { cb(); }
      },
      closeTls: function (cb) {
        if (self.tlsPortal && self.tlsPortal.address()) { self.tlsPortal.close(cb); } else { return cb(); }
      }
    }, callback);
  }, 1);
};

Stubby.prototype.post = function (data, callback) {
  var self = this;

  if (callback == null) { callback = noop; }

  setTimeout(function () {
    if (contract(data)) { callback(couldNotSave); } else { self.endpoints.create(data, callback); }
  }, 1);
};

Stubby.prototype.get = function (id, callback) {
  var self = this;

  if (id == null) { id = noop; }
  if (callback == null) { callback = id; }

  setTimeout(function () {
    if (typeof id === 'function') { self.endpoints.gather(callback); } else { self.endpoints.retrieve(id, callback); }
  }, 1);
};

Stubby.prototype.put = function (id, data, callback) {
  var self = this;

  if (callback == null) { callback = noop; }

  setTimeout(function () {
    if (contract(data)) { callback(couldNotSave); } else { self.endpoints.update(id, data, callback); }
  }, 1);
};

Stubby.prototype.delete = function (id, callback) {
  var self = this;

  if (id == null) { id = noop; }
  if (callback == null) { callback = id; }

  setTimeout(function () {
    if (typeof id === 'function') {
      delete self.endpoints.db;
      self.endpoints.db = {};
      callback();
    } else {
      self.endpoints.delete(id, callback);
    }
  }, 1);
};

module.exports.Stubby = Stubby;
