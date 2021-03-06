'use strict';

const fs = require('fs');
const crypto = require('crypto');
const contract = require('../models/contract');
const out = require('./out');
const yaml = require('js-yaml');

const interval = 3000;

class Watcher {
  constructor (endpoints, filename) {
    this.endpoints = endpoints;
    this.filename = filename;
    this.watching = false;
    this.intervalId = null;

    const shasum = crypto.createHash('sha1');
    shasum.update(fs.readFileSync(this.filename, 'utf8'));

    this.sha = shasum.digest('hex');
    this.activate();
  }

  deactivate () {
    this.watching = false;
    return clearInterval(this.intervalId);
  }

  activate () {
    if (this.watching) { return; }

    this.watching = true;
    out.status('Watching for changes in ' + this.filename + '...');
    this.intervalId = setInterval(this.refresh.bind(this), interval);
  }

  refresh () {
    let errors;
    const shasum = crypto.createHash('sha1');
    let data = fs.readFileSync(this.filename, 'utf8');

    shasum.update(data);
    const sha = shasum.digest('hex');

    if (sha !== this.sha) {
      try {
        data = yaml.load(data);
        errors = contract(data);

        if (errors) {
          out.error(errors);
        } else {
          this.endpoints.db = [];
          this.endpoints.create(data, function () {});
          out.notice('"' + this.filename + '" was changed. It has been reloaded.');
        }
      } catch (e) {
        out.warn('Couldn\'t parse "' + this.filename + '" due to syntax errors:');
        out.log(e.message);
      }
    }

    this.sha = sha;
  }
}

module.exports = Watcher;
