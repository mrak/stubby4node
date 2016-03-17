[![Build Status](https://secure.travis-ci.org/mrak/stubby4node.png?branch=master)](http://travis-ci.org/mrak/stubby4node)
[![NPM version](https://badge.fury.io/js/stubby.png)](http://badge.fury.io/js/stubby)

stubby4node
===========

A configurable server for mocking/stubbing external systems during development.

`stubby` takes endpoint descriptors in the form of a YAML or JSON file that tell it how to respond to incoming requests. For each incoming request, configured endpoints are checked in-order until a match is found.

## Table of Contents

* [Installation](#installation)
* [Requirements](#requirements)
* [Starting the Server(s)](#starting-the-servers)
* [Command-line Switches](#command-line-switches)
* [Endpoint Configuration](#endpoint-configuration)
* [Dynamic Token Interpolation](#dynamic-token-interpolation)
* [The Admin Portal](#the-admin-portal)
* [The Stubs Portal](#the-stubs-portal)
* [Programmatic API](#programmatic-api)
* [See Also](#see-also)
* [TODO](#todo)
* [NOTES](#notes)

## Installation

### via npm

    npm install -g stubby

This will install `stubby` as a command in your `PATH`. Leave off the `-g` flag if you'd like to use stubby as an embedded module in your project.

### via source

    git clone https://github.com/mrak/stubby4node.git
    cd stubby4node
    npm start -- <stubby args>

## Requirements

* [node.js](http://nodejs.org/)
  * iojs
  * 0.10.x
  * 0.12.x
  * node LTS
  * node latest

Development is on x86-64 Linux.

## Starting the Server(s)

Some systems require you to `sudo` before running services on port certain ports (like 80)

    [sudo] stubby

## Command-line Switches

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

When used from the command-line, `stubby` responds to the `SIGHUP` signal to reload its configuration.

## Endpoint Configuration

This section explains the usage, intent and behavior of each property on the `request` and `response` objects.

Here is a fully-populated, unrealistic endpoint:
```yaml
-  request:
      url: ^/your/awesome/endpoint$
      method: POST
      query:
         exclamation: post requests can have query strings!
      headers:
         content-type: application/xml
      post: >
         <!xml blah="blah blah blah">
         <envelope>
            <unaryTag/>
         </envelope>
      file: tryMyFirst.xml
   response:
    - status: 200
      latency: 5000
      headers:
         content-type: application/xml
         server: stubbedServer/4.2
      body: >
         <!xml blah="blah blah blah">
         <responseXML>
            <content></content>
         </responseXML>
      file: responseData.xml
    - status: 200
      body: "Haha!"
```

### request

This object is used to match an incoming request to stubby against the available endpoints that have been configured.

#### url (required)

* is a full-fledged __regular expression__
* This is the only required property of an endpoint.
* signify the url after the base host and port (i.e. after `localhost:8882`).
* any query parameters are stripped (so don't include them, that's what `query` is for).
    * `/url?some=value&another=value` becomes `/url`
* no checking is done for URI-encoding compliance.
    * If it's invalid, it won't ever trigger a match.

This is the simplest you can get:
```yaml
-  request:
      url: /
```

A demonstration using regular expressions:
```yaml
-  request:
      url: ^/has/to/begin/with/this/

-  request:
      url: /has/to/end/with/this/$

-  request:
      url: ^/must/be/this/exactly/with/optional/trailing/slash/?$
```

#### method

* defaults to `GET`.
* case-insensitive.
* can be any of the following:
    * HEAD
    * GET
    * POST
    * PUT
    * POST
    * DELETE
    * etc.

```yaml
-  request:
      url: /anything
      method: GET
```

* it can also be an array of values.

```yaml
-  request:
      url: /anything
      method: [GET, HEAD]

-  request:
     url: ^/yonder
     method:
       -  GET
       -  HEAD
       -  POST
```

#### query

* values are full-fledged __regular expressions__
* if omitted, stubby ignores query parameters for the given url.
* a yaml hashmap of variable/value pairs.
* allows the query parameters to appear in any order in a uri

* The following will match either of these:
    * `/with/parameters?search=search+terms&filter=month`
    * `/with/parameters?filter=month&search=search+terms`

```yaml
-  request:
     url: ^/with/parameters$
     query:
       search: search terms
       filter: month
```

__NOTE__: repeated querystring keys (often array representations) will have
their values converted to a comma-separated list.

```
/url?array=one&array=two
```

will be matched by:

```yaml
- request:
    url: ^/url$
    query:
      array: one,two
```

#### post

* is a full-fledged __regular expression__
* if omitted, any post data is ignored.
* the body contents of the server request, such as form data.

```yaml
-  request:
      url: ^/post/form/data$
      post: name=John&email=john@example.com
```

#### file

* if supplied, replaces `post` with the contents of the locally given file.
    * paths are relative from where the `--data` file is located
* if the file is not found when the request is made, falls back to `post` for matching.
* allows you to split up stubby data across multiple files

```yaml
-  request:
      url: ^/match/against/file$
      file: postedData.json
      post: '{"fallback":"data"}'
```

postedData.json
```json
{"fileContents":"match against this if the file is here"}
```

* if `postedData.json` doesn't exist on the filesystem when `/match/against/file` is requested, stubby will match post contents against `{"fallback":"data"}` (from `post`) instead.

#### json

* not used if `post` or `file` are present.
* will be parsed into a JavaScript object.
* allows you to specify a JSON string that will be deeply compared with a JSON request

Although not required, it is recommended to also specify a `application/json` header requirement.

```yaml
-  request:
      url: ^/match/against/jsonString$
      headers:
         content-type: application/json
      json: '{"key1":"value1","key2":"value2"}'
```

JSON strings may contain `"key": "value"` pairs in any order: `{"key1":"value1, "key2":"value2"}` is equivalent to `{"key2":"value2, "key1":"value1"}`

#### headers

* values are full-fledged __regular expressions__
* if omitted, stubby ignores headers for the given url.
* case-insensitive matching of header names.
* a hashmap of header/value pairs similar to `query`.

The following endpoint only accepts requests with `application/json` post values:

```yaml
-  request:
      url: /post/json
      method: post
      headers:
         content-type: application/json
```

### response

Assuming a match has been made against the given `request` object, data from `response` is used to build the stubbed response back to the client.

__ALSO:__ The `response` property can also be a yaml sequence of responses that cycle as each request is made.

__ALSO:__ The `response` property can also be a url (string) or sequence of object/urls. The url will be used to record a response object to be used in calls to stubby. When used this way, data from the `request` portion of the endpoint will be used to assemble a request to the url given as the `response`.

```yaml
- request:
    url: /single/object
  response:
    status: 204

- request:
    url: /single/url/to/record
  response: http://example.com

- request:
    url: /object/and/url/in/sequence
  response:
  - http://google.com
  - status: 200
    body: 'second hit'
```

#### status

* the HTTP status code of the response.
* integer or integer-like string.
* defaults to `200`.

```yaml
-  request:
      url: ^/im/a/teapot$
      method: POST
   response:
      status: 420
```

#### body

* contents of the response body
* defaults to an empty content body

```yaml
-  request:
      url: ^/give/me/a/smile$
   response:
      body: ':)'
```

#### file

* similar to `request.file`, but the contents of the file are used as the `body`.

```yaml
-  request:
      url: /
   response:
      file: extremelyLongJsonFile.json
```

#### headers

* similar to `request.headers` except that these are sent back to the client.

```yaml
-  request:
      url: ^/give/me/some/json$
   response:
      headers:
         content-type: application/json
      body: >
         [{
            "name":"John",
            "email":"john@example.com"
         },{
            "name":"Jane",
            "email":"jane@example.com"
         }]
```

#### latency

* time to wait, in milliseconds, before sending back the response
* good for testing timeouts, or slow connections

```yaml
-  request:
      url: ^/hello/to/jupiter$
   response:
      latency: 800000
      body: Hello, World!
```

## Dynamic Token Interpolation

While `stubby` is matching request data against configured endpoints, it is keeping a hash of all regular expression capture groups along the way.
These capture groups can be referenced in `response` data. Here's an example

```yaml
-  request:
      method: [GET]
      url: ^/account/(\d{5})/category/([a-zA-Z]+)
      query:
         date: "([a-zA-Z]+)"
      headers:
         custom-header: "[0-9]+"

   response:
      status: 200
      body: Returned invoice number# <% url[1] %> in category '<% url[2] %>' on the date '<% query.date[1] %>', using header custom-header <% headers.custom-header[0] %>
```

The `url` regex `^/account/(\d{5})/category/([a-zA-Z]+)` has two defined capturing groups: `(\d{5})` and `([a-zA-Z]+)`. The `query` regex has one defined capturing group: `([a-zA-Z]+)`.

Although the `headers` do not have capturing groups defined explicitly (no regex sections within parenthesis), the individual headers' fully-matched value is still accessible in a template (see [Capture group IDs](#capture-group-ids)).

### Templating `body` and `file`

The `response.body` can have token interpolations following the format of `< %PROPERTY_NAME[CAPTURING_GROUP_ID] %>`. If it is a token that corresponds to `headers` or `query` member matches, then the token structure would be `<% HEADERS_OR_QUERY.[KEY_NAME][CAPTURING_GROUP_ID] %>.

```yaml
  response:
    body: The "content-type" header value was <% headers.content-type[0] %>.
```

__NOTE:__ If you are using the `file` property for your responses, keep in mind that the
file _contents_ are interpolated, not the file _name_. In other words, the `<% ... %>` will appear in the files' contents and not on the line in your configuration that has `response.file`

### Capture group IDs

The `CAPTURING_GROUP_ID` is determined by the regular expression used. The index
of `0` will be the full-text that matches the regular expression.

Capture groups start at index `1` and correspond to the usage of parentheses.

Let's demonstrate with the example from above:

```
- request:
    url: ^/account/(\d{5})/category/([a-zA-Z]+)
```

If the incoming `url` is `/account/54/category/users`, the following would be
the capture groups:

```
<% url[0] %> -> /account/54/categroy/users
<% url[1] %> -> 54
<% url[2] %> -> users
```

Let's take a more complicated example with sub-groups as captures:

```yaml
- request:
    url: ^/resource/(([a-z]{3})-([0-9]{3}))$
```

If the incoming `url` is `/resource/abc-123`, the capture groups would be:

```
<% url[0] %> -> /resource/abc-123
<% url[1] %> -> abc-123
<% url[2] %> -> abc
<% url[3] %> -> 123
```

### Troubleshooting

* Make sure that the regex you used in your stubby configuration actually does what it supposed to do. Validate that it works via the node REPL (or similar) before using it in stubby
* Make sure that the regex has capturing groups for the parts of regex you want to capture as token values. In other words, make sure that you did not forget the parentheses within your regex if your token IDs start from `1`
* Make sure that you are using token ID zero when wanting to use __full__ regex match as the token value
* Make sure that the token names you used in your template are correct: check that property name is correct, capturing group IDs, token ID of the __full__ match, the `<%` and `%>`

## The Admin Portal

The admin portal is a RESTful(ish) endpoint running on `localhost:8889`. Or wherever you described through stubby's options.

### Supplying Endpoints to Stubby

Submit `POST` requests to `localhost:8889`, `PUT` requests to `localhost:8889/:id`[\*](#getting-the-id-of-a-loaded-endpoint), or load a data-file (-d) with the following structure for each endpoint:

* `request`: describes the client's call to the server
   * `method`: GET/POST/PUT/DELETE/etc.
   * `url`: the URI regex string.
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

#### YAML
```yaml
-  request:
      url: ^/path/to/something$
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
      url: ^/path/to/anotherThing
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
      url: ^/path/to/thing$
      method: POST
      headers:
         Content-Type: application/json
      post: this is some post data in textual format
   response:
      headers:
         Content-Type: application/json
      status: 304
```

#### JSON
```json
[
  {
    "request": {
      "url": "^/path/to/something$",
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
      "url": "^/path/to/anotherThing",
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
      "url": "^/path/to/thing$",
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

### Getting the ID of a Loaded Endpoint

Stubby adds the response-header `X-Stubby-Resource-ID` to outgoing responses. This ID can be referenced for use with the Admin portal.

### Getting the Current List of Stubbed Endpoints

Performing a `GET` request on `localhost:8889` will return a JSON array of all currently saved responses. It will reply with `204 : No Content` if there are none saved.

Performing a `GET` request on `localhost:8889/<id>` will return the JSON object representing the response with the supplied id.

#### The Status Page

You can also view the currently configured endpoints by going to `localhost:8889/status`

### Changing Existing Endpoints

Perform `PUT` requests in the same format as using `POST`, only this time supply the id in the path. For instance, to update the response with id 4 you would `PUT` to `localhost:8889/4`.

### Deleting Endpoints

Send a `DELETE` request to `localhost:8889/<id>`

## The Stubs Portal

Requests sent to any url at `localhost:8882` (or wherever you told stubby to run) will search through the available endpoints and, if a match is found, respond with that endpoint's `response` data

### How Endpoints Are Matched

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

## Programmatic API

### The Stubby module

Add `stubby` as a module within your project's directory:

```
    npm install stubby
```

Then within your project files you can do something like:

```javascript
    var Stubby = require('stubby').Stubby;
    var mockService = new Stubby();

    mockService.start();
```

What can I do with it, you ask? Read on!

#### start(options, [callback])

* `options`: an object containing parameters with which to start this stubby. Parameters go along with the full-name flags used from the command line.
   * `stubs`: port number to run the stubs portal
   * `admin`: port number to run the admin portal
   * `tls`: port number to run the stubs portal over https
   * `data`: JavaScript Object/Array containing endpoint data
   * `location`: address/hostname at which to run stubby.
   * `key`: keyfile contents (in PEM format)
   * `cert`: certificate file contents (in PEM format)
   * `pfx`: pfx file contents (mutually exclusive with key/cert options)
   * `watch`: filename to monitor and load as stubby's data when changes occur
   * `mute`: defaults to `true`. Pass in `false` to have console output (if available)
   * `_httpsOptions`: additional options to pass to the [underlying tls
     server](http://nodejs.org/api/tls.html#tls_tls_createserver_options_secureconnectionlistener).
* `callback`: takes one parameter: the error message (if there is one), undefined otherwise

#### start([callback])
Identical to previous signature, only all options are assumed to be defaults.

#### stop([callback])
closes the connections and ports being used by stubby's stubs and admin portals. Executes `callback` afterward.

#### get(id, callback)
Simulates a GET request to the admin portal, with the callback receiving the resultant data.

* `id`: the id of the endpoint to retrieve. If omitted, an array of all registered endpoints is passed the callback.
* `callback(err, endpoint)`: `err` is defined if no endpoint exists with the given id. Else, `endpoint` is populated.

#### get(callback)
Simulates a GET request to the admin portal, with the callback receiving the resultant data.

* `id`: the id of the endpoint to retrieve. If omitted, an array of all registered endpoints is passed the callback.
* `callback(endpoints)`: takes a single parameter containing an array of returned results. Empty if no endpoints are registered

#### post(data, [callback])
* `data`: an endpoint object to store in stubby
* `callback(err, endpoint)`: if all goes well, gets executed with the created endpoint. If there is an error, gets called with the error message.

#### put(id, data, [callback])
* `id`: id of the endpoint to update.
* `data`: data with which to replace the endpoint.
* `callback(err)`: executed with no passed parameters if successful. Else, passed the error message.

#### delete([id], callback)
* `id`: id of the endpoint to destroy. If omitted, all endoints are cleared from stubby.
* `callback()`: called after the endpoint has been removed

#### Example
```javascript
var Stubby = require('stubby').Stubby;

var stubby1 = new Stubby();
var stubby2 = new Stubby();

stubby1.start({
  stubs: 80,
  admin: 81,
  location: 'localhost',
  data: [{
    request: { url: "/anywhere" }
  },{
    request: { url: "/but/here" }
  }]
});

stubby2.start({
  stubs: 82,
  admin: 83,
  location: '127.0.0.2'
});
```

## See Also

* **[stubby4j](https://github.com/azagniotov/stubby4j):** A java implementation of stubby
* **[stubby4net](https://github.com/mrak/stubby4net):** A .NET implementation of stubby
* **[grunt-stubby](https://github.com/h2non/grunt-stubby):** grunt integration with stubby
* **[gulp-stubby-server](https://github.com/felixzapata/gulp-stubby-server):** gulp integration with stubby

## TODO

Non-breaking changes

* `post` parameter as a hashmap under `request` for easy form-submission value matching
* Allow multi-value fields (arrays and maps) as query/post params

Breaking changes

* Intepret configuration values beginning and ending with `/` as regular
  expressions, otherwise consider as exact string matches
  * if `/` surrounded values do not compile as regex, log error to
    console/response when adding

## NOTES

* __Copyright__ 2015 Eric Mrak, Alexander Zagniotov
* __License__ Apache v2.0
