# stubby4node

A configurable server for mocking/stubbing external systems during development. Uses Node.js and written in Coffeescript

## Requirements

* [node.js](http://nodejs.org/) (developed using v0.6.15)
* [CoffeeScript](http://coffeescript.org/)

### More Optionals (for debugging/testing)

* [JS-YAML](https://github.com/nodeca/js-yaml) for loading yaml files
* [node-inspector](https://github.com/dannycoates/node-inspector)
* [jasmine-node](https://github.com/mhevery/jasmine-node)

## Installation

    git clone git://github.com/Afmrak/node-stub-server.git
    npm install -g coffee-script

## Starting the Server(s)

Some systems require you to `sudo` before running services on port 80

    [sudo] coffee src/server.coffee

## Command-line switches

`--stub (-s) <port>` to supply a port number for the stub portal (defaults to 80)

`--admin (-a) <port>` to supply a port number for the admin portal (defaults to 81)

`--file (-f) file.{json|yml|yaml}` containing a list of endpoints to pre-populate the server with

## The Admin Portal

The admin portal is a RESTful endpoint running on `localhost:81`.

### POST a Stubbed Response

Submit `POST` requests to `localhost:81` or load a file with the following YAML structure.

```
request:
   url: /path/to/something?a=anything&b=more
   method: POST
   post: this is some post data in textual format
response:
   headers: {"Content-Type":"application/json"}
   status: 200
   content: You're request was successfully processed!
```

On success, the response will contain `Content-Location` in the header with the newly created resources' location

### GET the Current List of Stubbed Responses

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
* HTTP auth mocking
* Randomized responses based on supplied pattern (exploratory QA abuse)
