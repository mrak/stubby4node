[![Build Status](https://secure.travis-ci.org/Afmrak/stubby4node.png?branch=master)](http://travis-ci.org/Afmrak/stubby4node)

* [Installation](#installation)
    * [via npm](#via-npm)
    * [via source](#via-source)
* [Requirements](#requirements)
    * [Packaged](#packaged)
    * [Optional (for development)](#optional-for-development)
* [Starting the Server(s)](#starting-the-servers)
* [Command-line Switches](#command-line-switches)
* [The Admin Portal](#the-admin-portal)
    * [Supplying Endpoints to Stubby](#supplying-endpoints-to-stubby)
        * [YAML (file only)](#yaml-file-only)
        * [JSON (file or POST/PUT)](#json-file-or-postput)
    * [Getting the Current List of Stubbed Endpoints](#getting-the-current-list-of-stubbed-endpoints)
    * [Changing Existing Endpoints](#changing-existing-endpoints)
    * [Deleting Endpoints](#deleting-endpoints)
* [The Stubs Portal](#the-stubs-portal)
    * [How Endpoints Are Matched](#how-endpoints-are-matched)
* [Programmatic API](#programmatic-api)
    * [The Stubby Module](#the-stubby-module)
        * [start(options, [callback])](#startoptions-callback)
        * [stop([callback])](#stopcallback)
        * [get(id, callback)](#getid-callback)
        * [get(callback)](#getcallback)
        * [post(data, [callback])](#postdata-callback)
        * [put(id, data, [callback])](#putid-data-callback)
        * [delete([id], callback)](#deleteid-callback)
        * [Example (coffeescript)](#example-coffeescript)
* [Running Tests](#running-tests)
* [See Also](#see-also)
* [TODO](#todo)
* [Wishful Thinkings](#wishful-thinkings)
* [NOTES](#notes)

# Installation

## via npm

    npm install -g stubby

This will install `stubby` as a command in your `PATH`. Leave off the `-g` flag if you'd like to use stubby as an embedded module in your project.

## via source

You need to have `coffee-script` installed on your system.

    git clone git://github.com/Afmrak/stubby4node.git
    cd stubby4node
    coffee -o lib -c src
    export PATH=$PATH:<pwd>/bin/stubby

# Requirements

* [node.js](http://nodejs.org/) (tested with v0.8.x)

Development is on Mac OS X Mountain Lion.

## Packaged

* [JS-YAML](https://github.com/nodeca/js-yaml) for loading yaml files
* [cloneextend](https://github.com/shimondoodkin/nodejs-clone-extend)

## Optional (for development)

* [coffee-script](http://coffeescript.org)
* [node-inspector](https://github.com/dannycoates/node-inspector)
* [jasmine-node](https://github.com/mhevery/jasmine-node)

# Starting the Server(s)

Some systems require you to `sudo` before running services on port certain ports (like 80)

    [sudo] stubby

# Command-line Switches

```
stubby [-a <port>] [-c <file>] [-d <file>] [-h] [-k <file>] [-l <hostname>] [-m] [-p <file>]
       [-s <port>] [-t <port>] [-v] [-w]

-a, --admin <port>          Port for admin portal. Defaults to 8889.
-c, --cert <file>           Certificate file. Use with --key.
-d, --data <file>           Data file to pre-load endoints. YAML or JSON format.
-h, --help                  This help text.
-k, --key <file>            Private key file. Use with --cert.
-l, --location <hostname>   Hostname at which to bind stubby.
-m, --mute                  Prevent stubby from printing to the console.
-p, --pfx <file>            PFX file. Ignored if used with --key/--cert
-s, --stubs <port>          Port for stubs portal. Defaults to 8882.
-t, --tls <port>            Port for https stubs portal. Defaults to 7443.
-v, --version               Prints stubby's version number.
-w, --watch                 Auto-reload data file when edits are made.
```

# The Admin Portal

The admin portal is a RESTful(ish) endpoint running on `localhost:8889`. Or wherever you described through stubby's options.

## Supplying Endpoints to Stubby

Submit `POST` requests to `localhost:8889` or load a data-file (-d) with the following structure for each endpoint:

* `request`: describes the client's call to the server
   * `method`: GET/POST/PUT/DELETE/etc.
   * `url`: the URI string. GET parameters should also be included inline here
   * `query`: a key/value map of query string parameters included with the request
   * `headers`: a key/value map of headers the server should respond to
   * `post`: a string matching the textual body of the response.
   * `file`: if specified, returns the contents of the given file as the request post. If the file cannot be found at request time, **post** is used instead
* `response`: describes the server's response to the client
   * `headers`: a key/value map of headers the server should use in it's response
   * `latency`: the time in milliseconds the server should wait before responding. Useful for testing timeouts and latency
   * `file`: if specified, returns the contents of the given file as the response body. If the file cannot be found at request time, **body** is used instead
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
      url: /path/to/anotherThing
      query:
         a: anything
         b: more
      method: GET
      headers:
         Content-Type: application/json
      post:
   response:
      headers:
         Content-Type: application/json
         Access-Control-Allow-Origin: "*"
      status: 204
      file: path/to/page.html

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
      "url": "/path/to/anotherThing", 
      "query": {
         "a": "anything",
         "b": "more"
      },
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
      "file": "path/to/page.html"
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
      } 
    }
  }
]
```

If you want to load more than one endpoint via file, use either a JSON array or YAML list (-) syntax. On success, the response will contain `Location` in the header with the newly created resources' location

## Getting the Current List of Stubbed Endpoints

Performing a `GET` request on `localhost:8889` will return a JSON array of all currently saved responses. It will reply with `204 : No Content` if there are none saved.

Performing a `GET` request on `localhost:8889/<id>` will return the JSON object representing the response with the supplied id.

## Changing Existing Endpoints

Perform `PUT` requests in the same format as using `POST`, only this time supply the id in the path. For instance, to update the response with id 4 you would `PUT` to `localhost:8889/4`.

## Deleting Endpoints

Send a `DELETE` request to `localhost:8889/<id>`

# The Stubs Portal

Requests sent to any url at `localhost:8882` (or wherever you told stubby to run) will search through the available endpoints and, if a match is found, respond with that endpoint's `response` data

## How Endpoints Are Matched

For a given endpoint, stubby only cares about matching the properties of the request that have been defined in the YAML. The exception to this rule is `method`; if it is omitted it is defaulted to `GET`.

For instance, the following will match any `POST` request to the root url:

```yaml
-  request:
      url: /
      method: POST
   response: {}
```

The request could have any headers and any post body it wants. It will match the above.

Pseudocode:

```
for each <endpoint> of stored endpoints {

   for each <property> of <endpoint> {
      if <endpoint>.<property> != <incoming request>.<property>
         next endpoint
   }

   return <endpoint>
}
```

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
   * `stubs`: port number to run the stubs portal
   * `admin`: port number to run the admin portal
   * `tls`: port number to run the stubs portal over https
   * `data`: JavaScript Object/Array containing endpoint data
   * `location`: address/hostname at which to run stubby
   * `key`: keyfile contents (in PEM format)
   * `cert`: certificate file contents (in PEM format)
   * `pfx`: pfx file contents (mutually exclusive with key/cert options)
   * `watch`: filename to monitor and load as stubby's data when changes occur
   * `mute`: defaults to `true`. Pass in `false` to have console output (if available)
* `callback`: takes one parameter: the error message (if there is one), undefined otherwise

### start([callback])
Identical to previous signature, only all options are assumed to be defaults.

### stop([callback])
closes the connections and ports being used by stubby's stubs and admin portals. Executes `callback` afterward.

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
   stubs: 80
   admin: 81
   location: 'localhost'
   data: [
      request:
         url: "/anywhere"
   ,
      request:
         url: "/but/here"
   ]

stubby2.start
   stubs: 82
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

* status page (`/ping` already available under admin portal)
* `post` parameter as a hashmap under `request` for easy form-submission value matching

# Wishful Thinkings

* SOAP request/response compliance
* Randomized responses based on supplied pattern (exploratory QA abuse)
* Minify js in `npm` module?

# NOTES

* __Copyright__ 2012 Eric Mrak, Alexander Zagniotov, Isa Goksu
* __License__ Apache v2.0

