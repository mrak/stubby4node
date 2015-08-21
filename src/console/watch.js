'use strict';

var fs = require('fs');
var crypto = require('crypto');
var contract = require('../models/contract');
var out = require('./out');
var yaml = require('js-yaml');

var interval = 3000;
var intervalId = null;
var watching = false;

function Watcher(endpoints, filename) {
  var shasum;

  this.endpoints = endpoints;
  this.filename = filename;

  shasum = crypto.createHash('sha1');
  shasum.update(fs.readFileSync(this.filename, 'utf8'));

  this.sha = shasum.digest('hex');
  this.activate();
}

Watcher.prototype.deactivate = function () {
  watching = false;
  return clearInterval(intervalId);
};

Watcher.prototype.activate = function () {
  if (watching) { return; }

  watching = true;
  out.status('Watching for changes in ' + this.filename + '...');
  intervalId = setInterval(this.refresh.bind(this), interval);
};

Watcher.prototype.refresh = function () {
  var sha, errors;
  var shasum = crypto.createHash('sha1');
  var data = fs.readFileSync(this.filename, 'utf8');

  shasum.update(data);
  sha = shasum.digest('hex');

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
};

module.exports = Watcher;
