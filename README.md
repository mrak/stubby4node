[![Build Status](https://secure.travis-ci.org/Afmrak/stubby4node.png?branch=master)](http://travis-ci.org/Afmrak/stubby4node)

# Requirements

* [node.js](http://nodejs.org/) (tested with v0.6.x and v0.8.x)

## Packaged

* [coffee-script](http://coffeescript.org)
* [JS-YAML](https://github.com/nodeca/js-yaml) for loading yaml files

## Optional (for debugging/testing)

* [node-inspector](https://github.com/dannycoates/node-inspector)
* [jasmine-node](https://github.com/mhevery/jasmine-node)

# Installation

## via source

    git clone git://github.com/Afmrak/stubby4node.git
    cd stubby4node
    cake build

## via npm

    npm install -g stubby

This will create the executable `stubby` in the root level of the project.

# Starting the Server(s)

Some systems require you to `sudo` before running services on port certain ports (like 80)

    [sudo] stubby

# Command-line switches

```
stubby [-s <port>] [-a <port>] [-d <file>] [-l <hostname>]
       [-h] [-v] [-k <file>] [-c <file>] [-p <file>]

-s, --stub [PORT]                    Port that stub portal should run on. Defaults to 8882.

-a, --admin [PORT]                   Port that admin portal should run on. Defaults to 8889.

-d, --data [FILE.{json|yml|yaml}]    Data file to pre-load endoints.

-l, --location [HOSTNAME]            Host at which to run stubby.

-h, --help                           This help text.

-v, --version                        Prints stubby's version number.

-k, --key [FILE.pem]                 Private key file in PEM format for https. Requires --cert

-c, --cert [FILE.pem]                Certificate key file in PEM format for https. Requres --key.

-p, --pfx [FILE.pfx]                 Key, certificate key and trusted certificates in pfx
                                     format. Mutually exclusive with --key,--cert
```

# The Admin Portal

The admin portal is a RESTful(ish) endpoint running on `localhost:8889`.

## Supplying Endpoints to Stub

Submit `POST` requests to `localhost:8889` or load a file (-f) with the following structure:

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

If you want to load more than one endpoint via file, use either a JSON array or YAML list (-) syntax. On success, the response will contain `Content-Location` in the header with the newly created resources' location

## Getting the Current List of Stubbed Responses

Performing a `GET` request on `localhost:8889` will return a JSON array of all currently saved responses. It will reply with `204 : No Content` if there are none saved.

Performing a `GET` request on `localhost:8889/<id>` will return the JSON object representing the response with the supplied id.

## Change existing responses

Perform `PUT` requests in the same format as using `POST`, only this time supply the id in the path. For instance, to update the response with id 4 you would `PUT` to `localhost:8889/4`.

## Deleting responses

Send a `DELETE` request to `localhost:8889/<id>`

# The Stub Portal

Requests sent to any url at `localhost` or `localhost:8882` will search through the available endpoints and, if a match is found, respond with that endpoint's `response` data

# Running tests

If you don't have jasmine-node already, install it:

    npm install -g jasmine-node

From the root directory run:

    jasmine-node --coffee spec

# See Also

**[stubby4j](https://github.com/azagniotov/stubby4j):** A java implementation of stubby

# TODO

* `PUT`ing multiple responses at a time.
* SOAP request/response compliance
* Dynamic port switching
* HTTP/SSL auth mocking
* Randomized responses based on supplied pattern (exploratory QA abuse)

# NOTES

* __Copyright__ 2012 Eric Mrak, Alexander Zagniotov, Isa Goksu
* __License__ Apache v2.0

