# stubby4node

A light-weight (9kb) configurable server for mocking/stubbing external systems during development. Uses Node.js and written in Coffeescript

## Requirements

* [node.js](http://nodejs.org/) (tested with v0.6.15-v0.8.2)
* [CoffeeScript](http://coffeescript.org/)

### More Optionals (for debugging/testing)

* [JS-YAML](https://github.com/nodeca/js-yaml) for loading yaml files
* [node-inspector](https://github.com/dannycoates/node-inspector)
* [jasmine-node](https://github.com/mhevery/jasmine-node)

## Installation
Assuming you have node and Coffee-Script installed:

    git clone git://github.com/Afmrak/stubby4node.git
    cd stubby4node
    cake build

This will create the executable `stubby4node` in the root level of the project.

## Starting the Server(s)

Some systems require you to `sudo` before running services on port 80

    [sudo] ./stubby4node

## Command-line switches

```
stubby4node [-s <port>] [-a <port>] [-f <file>] [-h]

-s, --stub [PORT]                    port that stub portal should run on
-a, --admin [PORT]                   port that admin portal should run on
-f, --file [FILE.{json|yml|yaml}]    data file to pre-load endoints
-h, --help                           this help text
```

## The Admin Portal

The admin portal is a RESTful(ish) endpoint running on `localhost:81`.

### Supplying Endpoints to Stub

Submit `POST` requests to `localhost:81` or load a file (-f) with the following structure:

* `request`: describes the client's call to the server
   * `method`: GET/POST/PUT/DELETE/etc.
   * `url`: the URI string. GET parameters should also be included inline here
   * `post`: a string matching the textual body of the response.
* `response`: describes the server's response to the client
   * `headers`: a key/value map of headers the server should use in it's response
   * `latency`: the time in milliseconds the server should wait before responding. Useful for testing timeouts and latency
   * `body`: the textual body of the server's response to the client
   * `status`: the numerical HTTP status code (200 for OK, 404 for NOT FOUND, etc.)

#### YAML (file only)
```yaml
-  request:
      url: /path/to/something
      method: POST
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
      post: this is some post data in textual format
   response:
      headers:
         Content-Type: application/json
      status: 304
      body:
```

#### JSON (file or POST/PUT)
```json
[
  {
    "request": {
      "url": "/path/to/something", 
      "post": "this is some post data in textual format", 
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

### Getting the Current List of Stubbed Responses

Performing a `GET` request on `localhost:81` will return a JSON array of all currently saved responses. It will reply with `204 : No Content` if there are none saved.

Performing a `GET` request on `localhost:81/<id>` will return the JSON object representing the response with the supplied id.

### Change existing responses

Perform `PUT` requests in the same format as using `POST`, only this time supply the id in the path. For instance, to update the response with id 4 you would `PUT` to `localhost:81/4`.

### Deleting responses

Send a `DELETE` request to `localhost:81/<id>`

## The Stub Portal

Requests sent to any url at `localhost` or `localhost:80` will search through the available endpoints and, if a match is found, respond with that endpoint's `response` data

## Running tests

If you don't have jasmine-node already, install it:

    npm install -g jasmine-node

From the root directory run:

    jasmine-node --coffee spec

## TODO

* `PUT`ing multiple responses at a time.
* SOAP request/response compliance
* Dynamic port switching
* HTTP/SSL auth mocking
* Randomized responses based on supplied pattern (exploratory QA abuse)
