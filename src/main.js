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

function onEndpointLoaded (endpoint) {
  out.notice('Loaded: ' + endpoint.request.method + ' ' + endpoint.request.url);
}

function setupStartOptions (options) {
  let key;

  options = options == null ? {} : options;

  if (options.quiet == null) { options.quiet = true; }

  const defaults = CLI.getArgs([]);
  for (key in defaults) {
    if (options[key] == null) {
      options[key] = defaults[key];
    }
  }

  out.quiet = options.quiet;
  return options;
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

class Stubby {
  constructor () {
    this.endpoints = new Endpoints();
    this.stubsPortal = null;
    this.tlsPortal = null;
    this.adminPortal = null;
  }

  async start (o) {
    const options = setupStartOptions(o);

    await this.stop();

    const errors = contract(options.data);

    if (errors) { throw new Error(errors); }
    if (options.datadir != null) { this.endpoints.datadir = options.datadir; }
    if (options['case-sensitive-headers'] != null) { this.endpoints.caseSensitiveHeaders = options['case-sensitive-headers']; }

    await this.endpoints.create(options.data, onEndpointLoaded);

    this.tlsPortal = https.createServer(createHttpsOptions(options), new Stubs(this.endpoints).server);
    this.tlsPortal.on('listening', function () { onListening('Stubs', options.tls, 'https', options.location); });
    this.tlsPortal.on('error', function (err) { onError(err, options.tls, options.location); });
    this.tlsPortal.listen(options.tls, options.location);

    this.stubsPortal = http.createServer(new Stubs(this.endpoints).server);
    this.stubsPortal.on('listening', function () { onListening('Stubs', options.stubs, 'http', options.location); });
    this.stubsPortal.on('error', function (err) { onError(err, options.stubs, options.location); });
    this.stubsPortal.listen(options.stubs, options.location);

    this.adminPortal = http.createServer(new Admin(this.endpoints).server);
    this.adminPortal.on('listening', function () { onListening('Admin', options.admin, 'http', options.location); });
    this.adminPortal.on('error', function (err) { onError(err, options.admin, options.location); });
    this.adminPortal.listen(options.admin, options.location);

    if (options.watch) { this.watcher = new Watcher(this.endpoints, options.watch); }

    out.info('\nQuit: ctrl-c\n');
  }

  async stop () {
    if (this.watcher != null) { this.watcher.deactivate(); }

    if (this.adminPortal && this.adminPortal.address()) { await promisify(this.adminPortal, 'close'); }
    if (this.stubsPortal && this.stubsPortal.address()) { await promisify(this.stubsPortal, 'close'); }
    if (this.tlsPortal && this.tlsPortal.address()) { await promisify(this.tlsPortal, 'close'); }
  }

  async post (data) {
    if (contract(data)) {
      throw new Error(couldNotSave);
    } else {
      await this.endpoints.create(data);
    }
  }

  async get (id) {
    if (id == null) await this.endpoints.gather();
    else await this.endpoints.retrieve(id);
  }

  async put (id, data) {
    if (contract(data)) throw new Error(couldNotSave);
    else await this.endpoints.update(id, data);
  }

  async delete (id) {
    if (id == null) await this.endpoints.deleteAll();
    else await this.endpoints.delete(id);
  }
}

function promisify (obj, method) {
  return new Promise((resolve, reject) => {
    obj[method]((err) => {
      if (err) reject(err);
      else resolve();
    });
  });
}

module.exports.Stubby = Stubby;
