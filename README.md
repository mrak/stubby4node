[![Build Status](https://secure.travis-ci.org/Afmrak/stubby4node.png?branch=master)](http://travis-ci.org/Afmrak/stubby4node)

# Requirements

* [node.js](http://nodejs.org/) (tested with v0.6.x and v0.8.x)

## Packaged

* [JS-YAML](https://github.com/nodeca/js-yaml) for loading yaml files
* [cloneextend](https://github.com/shimondoodkin/nodejs-clone-extend)

## Optional (for development)

* [coffee-script](http://coffeescript.org)
* [node-inspector](https://github.com/dannycoates/node-inspector)
* [jasmine-node](https://github.com/mhevery/jasmine-node)

# Installation

## via source

You need to have `coffee-script` installed on your system.

    git clone git://github.com/Afmrak/stubby4node.git
    cd stubby4node
    coffee -o lib -c src
    export PATH=$PATH:./bin/stubby

## via npm

    npm install -g stubby

This will install `stubby` as a command in your `PATH`.

# Starting the Server(s)

Some systems require you to `sudo` before running services on port certain ports (like 80)

    [sudo] stubby

# Command-line switches

```
stubby [-a <port>] [-c <file>] [-d <file>] [-h] [-k <file>]
       [-l <hostname>] [-s <port>] [-p <file>] [-v]

-a, --admin <port>          Port for admin portal. Defaults to
                            8889.
-c, --cert <file>           Certificate file. Use with --key.
-d, --data <file>           Data file to pre-load endoints. YAML
                            or JSON format.
-h, --help                  This help text.
-k, --key <file>            Private key file. Use with --cert.
-l, --location <hostname>   Hostname at which to bind stubby.
-s, --stub <port>           Port for stub portal. Defaults to
                            8882.
-p, --pfx <file>            PFX file. Ignored if used with
                            --key/--cert
-v, --version               Prints stubby's version number.
```

# The Admin Portal

The admin portal is a RESTful(ish) endpoint running on `localhost:8889`. Or wherever you described through stubby's options.

## Supplying Endpoints to Stubby

Submit `POST` requests to `localhost:8889` or load a data-file (-d) with the following structure for each endpoint:

* `request`: describes the client's call to the server
   * `method`: GET/POST/PUT/DELETE/etc.
   * `url`: the URI string. GET parameters should also be included inline here
   * `headers`: a key/value map of headers the server should respond to
   * `post`: a string matching the textual body of the response.
* `response`: describes the server's response to the client
   * `headers`: a key/value map of headers the server should use in it's response
   * `latency`: the time in milliseconds the server should wait before responding. Useful for testing timeouts and latency
   * `body`: the textual body of the server's response to the client
   * `status`: the numerical HTTP status code (200 for OK, 404 for NOT FOUND, etc.)

### YAML (file only)
```yaml
-  request:
      url: /path/to/something
      method: POST
      headers:
         authorization: "Basic usernamez:passwordinBase64"
      post: this is some post data in textual format
   response:
      headers:
         Content-Type: application/json
      latency: 1000
      status: 200
      body: You're request was successfully processed!

-  request:
      url: /path/to/anotherThing?a=anything&b=more
      method: GET
      headers:
         Content-Type: application/json
      post:
   response:
      headers:
         Content-Type: application/json
         Access-Control-Allow-Origin: "*"
      status: 204
      body:

-  request:
      url: /path/to/thing
      method: POST
      headers:
         Content-Type: application/json
      post: this is some post data in textual format
   response:
      headers:
         Content-Type: application/json
      status: 304
      body:
```

### JSON (file or POST/PUT)
```json
[
  {
    "request": {
      "url": "/path/to/something", 
      "post": "this is some post data in textual format", 
      "headers": {
         "authorization": "Basic usernamez:passwordinBase64"
      },
      "method": "POST"
    }, 
    "response": {
      "status": 200, 
      "headers": {
        "Content-Type": "application/json"
      },
      "latency": 1000,
      "body": "You're request was successfully processed!"
    }
  }, 
  {
    "request": {
      "url": "/path/to/anotherThing?a=anything&b=more", 
      "headers": {
        "Content-Type": "application/json"
      },
      "post": null, 
      "method": "GET"
    }, 
    "response": {
      "status": 204, 
      "headers": {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      }, 
      "body": null
    }
  }, 
  {
    "request": {
      "url": "/path/to/thing", 
      "headers": {
        "Content-Type": "application/json"
      },
      "post": "this is some post data in textual format", 
      "method": "POST"
    }, 
    "response": {
      "status": 304, 
      "headers": {
        "Content-Type": "application/json"
      }, 
      "body": null
    }
  }
]
```

If you want to load more than one endpoint via file, use either a JSON array or YAML list (-) syntax. On success, the response will contain `Location` in the header with the newly created resources' location

## Getting the Current List of Stubbed Endpoints

Performing a `GET` request on `localhost:8889` will return a JSON array of all currently saved responses. It will reply with `204 : No Content` if there are none saved.

Performing a `GET` request on `localhost:8889/<id>` will return the JSON object representing the response with the supplied id.

## Changing existing responses

Perform `PUT` requests in the same format as using `POST`, only this time supply the id in the path. For instance, to update the response with id 4 you would `PUT` to `localhost:8889/4`.

## Deleting responses

Send a `DELETE` request to `localhost:8889/<id>`

# The Stub Portal

Requests sent to any url at `localhost:8882` (or wherever you told stubby to run) will search through the available endpoints and, if a match is found, respond with that endpoint's `response` data

# Programmatic API

## The Stubby module

Add `stubby` as a module within your project's directory:

```
    npm install stubby
```

Then within your project files you can do something like:

```javascript
    var Stubby = require('stubby').Stubby;
    var mockExternalService = new Stubby();

    mockService.start();
```

What can I do with it, you ask? Read on!

### start(options, [callback])

* `options`: an object containing parameters with which to start this stubby. Parameters go along with the full-name flags used from the command line.
   * `stub`: port number to run the stub portal
   * `admin`: port number to run the admin portal
   * `data`: JavaScript Object/Array containing endpoint data
   * `location`: address/hostname at which to run stubby
   * `key`: keyfile contents (in PEM format)
   * `cert`: certificate file contents (in PEM format)
   * `pfx`: pfx file contents (mutually exclusive with key/cert options)
* `callback`: takes one parameter: the error message (if there is one), undefined otherwise

### start([callback])
Identical to previous signature, only all options are assumed to be defaults.

### stop()
closes the connections and ports being used by stubby's stub and admin portals

### get(id, callback)
Simulates a GET request to the admin portal, with the callback receiving the resultant data.

* `id`: the id of the endpoint to retrieve. If ommitted, an array of all registered endpoints is passed the callback.
* `callback(err, endpoint)`: `err` is defined if no endpoint exists with the given id. Else, `endpoint` is populated.

### get(callback)
Simulates a GET request to the admin portal, with the callback receiving the resultant data.

* `id`: the id of the endpoint to retrieve. If ommitted, an array of all registered endpoints is passed the callback.
* `callback(endpoints)`: takes a single parameter containing an array of returned results. Empty if no endpoints are registered

### post(data, [callback])
* `data`: an endpoint object to store in stubby
* `callback(err, endpoint)`: if all goes well, gets executed with the created endpoint. If there is an error, gets called with the error message.

### put(id, data, [callback])
* `id`: id of the endpoint to update.
* `data`: data with which to replace the endpoint.
* `callback(err)`: executed with no passed parameters if successful. Else, passed the error message.

### delete([id], callback)
* `id`: id of the endpoint to destroy. If ommitted, all endoints are cleared from stubby.
* `callback()`: called after the endpoint has been removed

### Example (coffeescript)
```coffeescript
Stubby = require('stubby').Stubby

stubby1 = new Stubby()
stubby2 = new Stubby()

stubby1.start
   stub: 80
   admin: 81
   location: 'localhost'

stubby2.start
   stub: 82
   admin: 83
   location: '127.0.0.2'
```

# Running Tests

If you don't have `jasmine-node` already, install it:

    npm install -g jasmine-node

From the root directory run:

    jasmine-node --coffee spec

If you want to see more informative output:

    jasmine-node --verbose --coffee spec

# See Also

**[stubby4j](https://github.com/azagniotov/stubby4j):** A java implementation of stubby

# TODO

* Better callback handling with programmatic API
* SOAP request/response compliance
* Randomized responses based on supplied pattern (exploratory QA abuse)
* On-the-fly changes of endpoint properties, such as changing an endpoint's url without resubmitting the endpoint's entire JSON string to the admin portal.
* Minify js in `npm` module?

# NOTES

* __Copyright__ 2012 Eric Mrak, Alexander Zagniotov, Isa Goksu
* __License__ Apache v2.0

