'use strict';

function contract(endpoint) {
  var errors = [];

  if (typeof endpoint === 'string') {
    try {
      endpoint = JSON.parse(endpoint);
    } catch (e) {
      return [messages.json];
    }
  }

  if (endpoint instanceof Array) {
    var results = endpoint.map(function (it) { return contract(it) });
    results = results.filter(function(result) { return result !== null; });

    if (results.length === 0) { return null; }
    else { return results; }
  }

  if (!endpoint.request) {
    errors.push(messages.request.missing);
  } else {
    for (var property in request) {
      errors.push(request[property](endpoint.request[property]));
    }
  }

  if (endpoint.response) {
    if (!(endpoint.response instanceof Array)) {
      endpoint.response = [endpoint.response];
    }

    endpoint.response.forEach(function(incoming) {
      for (property in response) {
        errors.push(response[property](incoming[property]));
      }
    });
  }

  errors = errors.filter(function(error) { return error !== null; });
  if (errors.length === 0) { errors = null; }
  return errors;
}

var httpMethods = [
  'GET',
  'PUT',
  'POST',
  'HEAD',
  'PATCH',
  'TRACE',
  'DELETE',
  'CONNECT',
  'OPTIONS'
];

var messages = {
  json: "An unparseable JSON string was supplied.",
  request: {
    missing: "'request' object is required.",
    url: "'request.url' is required.",
    query: {
      type: "'request.query', if supplied, must be an object."
    },
    method: "'request.method' must be one of " + httpMethods + ".",
    headers: {
      type: "'request.headers', if supplied, must be an object."
    }
  },
  response: {
    headers: {
      type: "'response.headers', if supplied, must be an object."
    },
    status: {
      type: "'response.status' must be integer-like.",
      small: "'response.status' must be >= 100.",
      large: "'response.status' must be < 600."
    },
    latency: {
      type: "'response.latency' must be integer-like."
    }
  }
};

var request = {
  url: function(url) {
    if (url) { return null; }

    return messages.request.url;
  },
  headers: function(headers) {
    if (!headers) { return null; }

    if (headers instanceof Array || typeof headers !== 'object') {
      return messages.request.headers.type;
    }

    return null;
  },
  method: function(method) {
    var each, _fn, _i, _len, _ref;
    if (!method) { return null; }

    if (!(method instanceof Array)) {
      if (httpMethods.indexOf(method.toUpperCase()) !== -1) {
        return null;
      } else {
        return messages.request.method;
      }
    }

    for (var i = 0; i < method.length; i++) {
      if (httpMethods.indexOf(method[i].toUpperCase()) === -1) {
        return messages.request.method;
      }
    }

    return null;
  },
  query: function(query) {
    if (!query) { return null; }

    if (query instanceof Array || typeof query !== 'object') {
      return messages.request.query.type;
    }

    return null;
  }
};

var response = {
  status: function(status) {
    if (!status) { return null; }

    var parsed = parseInt(status);

    if (!parsed) { return messages.response.status.type; }
    if (parsed < 100) { return messages.response.status.small; }
    if (parsed >= 600) { return messages.response.status.large; }

    return null;
  },
  headers: function(headers) {
    if (!headers) { return null; }

    if (headers instanceof Array || typeof headers !== 'object') {
      return messages.response.headers.type;
    }

    return null;
  },
  latency: function(latency) {
    if (!latency) { return null; }
    if (!parseInt(latency)) { return messages.response.latency.type; }

    return null;
  }
};

module.exports = contract;
