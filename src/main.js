'use strict';

const Admin = require('./portals/admin').Admin;
const Stubs = require('./portals/stubs').Stubs;
const Endpoints = require('./models/endpoints').Endpoints;
const Watcher = require('./console/watch');
const CLI = require('./console/cli');
const out = require('./console/out');
const http = require('http');
const https = require('https');
const contract = require('./models/contract');
const couldNotSave = "The supplied endpoint data couldn't be saved";

function noop () {}

function onListening (portal, port, protocol, location) {
  if (protocol == null) { protocol = 'http'; }
  out.status(portal + ' portal running at ' + protocol + '://' + location + ':' + port);
}

function onError (err, port, location) {
  let msg;

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

function onEndpointLoaded (_, endpoint) {
  out.notice('Loaded: ' + endpoint.request.method + ' ' + endpoint.request.url);
}

function setupStartOptions (options, callback) {
  let key;

  options = options == null ? {} : options;
  callback = callback == null ? noop : callback;

  if (typeof options === 'function') {
    callback = options;
    options = {};
  }

  if (options.quiet == null) { options.quiet = true; }

  const defaults = CLI.getArgs([]);
  for (key in defaults) {
    if (options[key] == null) {
      options[key] = defaults[key];
    }
  }

  out.quiet = options.quiet;
  return [options, callback];
}

function createHttpsOptions (options) {
  const httpsOptions = options._httpsOptions || {};

  if (options.key && options.cert) {
    httpsOptions.key = options.key;
    httpsOptions.cert = options.cert;
  } else if (options.pfx) {
    httpsOptions.pfx = options.pfx;
  }

  return httpsOptions;
}

function Stubby () {
  this.endpoints = new Endpoints();
  this.stubsPortal = null;
  this.tlsPortal = null;
  this.adminPortal = null;
}

Stubby.prototype.start = function (o, cb) {
  const oc = setupStartOptions(o, cb);
  const options = oc[0];
  const callback = oc[1];
  const self = this;

  this.stop(function () {
    const errors = contract(options.data);

    if (errors) { return callback(errors); }
    if (options.datadir != null) { self.endpoints.datadir = options.datadir; }
    if (options['case-sensitive-headers'] != null) { self.endpoints.caseSensitiveHeaders = options['case-sensitive-headers']; }

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
  const self = this;

  if (callback == null) { callback = noop; }

  setTimeout(function () {
    if (self.watcher != null) { self.watcher.deactivate(); }

    Promise.all([
      new Promise((resolve) => {
        if (self.adminPortal && self.adminPortal.address()) { self.adminPortal.close(resolve); } else { resolve(); }
      }),
      new Promise((resolve) => {
        if (self.stubsPortal && self.stubsPortal.address()) { self.stubsPortal.close(resolve); } else { resolve(); }
      }),
      new Promise((resolve) => {
        if (self.tlsPortal && self.tlsPortal.address()) { self.tlsPortal.close(resolve); } else { return resolve(); }
      })
    ]).then((results) => callback());
  }, 1);
};

Stubby.prototype.post = function (data, callback) {
  const self = this;

  if (callback == null) { callback = noop; }

  setTimeout(function () {
    if (contract(data)) { callback(couldNotSave); } else { self.endpoints.create(data, callback); }
  }, 1);
};

Stubby.prototype.get = function (id, callback) {
  const self = this;

  if (id == null) { id = noop; }
  if (callback == null) { callback = id; }

  setTimeout(function () {
    if (typeof id === 'function') { self.endpoints.gather(callback); } else { self.endpoints.retrieve(id, callback); }
  }, 1);
};

Stubby.prototype.put = function (id, data, callback) {
  const self = this;

  if (callback == null) { callback = noop; }

  setTimeout(function () {
    if (contract(data)) { callback(couldNotSave); } else { self.endpoints.update(id, data, callback); }
  }, 1);
};

Stubby.prototype.delete = function (id, callback) {
  const self = this;

  if (id == null) { id = noop; }
  if (callback == null) { callback = id; }

  setTimeout(function () {
    if (typeof id === 'function') {
      self.endpoints.deleteAll(callback);
    } else {
      self.endpoints.delete(id, callback);
    }
  }, 1);
};

module.exports.Stubby = Stubby;
