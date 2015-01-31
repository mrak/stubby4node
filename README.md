[![Build Status](https://secure.travis-ci.org/mrak/stubby4node.png?branch=master)](http://travis-ci.org/mrak/stubby4node)
[![NPM version](https://badge.fury.io/js/stubby.png)](http://badge.fury.io/js/stubby)

stubby4node
===========

## Table of Contents

* [Installation](#installation)
* [Requirements](#requirements)
* [Starting the Server(s)](#starting-the-servers)
* [Command-line Switches](#command-line-switches)
* [Endpoint Configuration](#endpoint-configuration)
* [Dynamic Token Replacement](#dynamic-token-replacement)
* [The Admin Portal](#the-admin-portal)
* [The Stubs Portal](#the-stubs-portal)
* [Programmatic API](#programmatic-api)
* [Running Tests](#running-tests)
* [Contributing](#contributing)
* [See Also](#see-also)
* [TODO](#todo)
* [NOTES](#notes)

## Installation

### via npm

    npm install -g stubby

This will install `stubby` as a command in your `PATH`. Leave off the `-g` flag if you'd like to use stubby as an embedded module in your project.

### via source

    git clone git://github.com/Afmrak/stubby4node.git
    cd stubby4node
    npm start -- <stubby args>

## Requirements

* [node.js](http://nodejs.org/) (>=0.10.x)

Development is on x86-64 Linux.

### Packaged

* [JS-YAML](https://github.com/nodeca/js-yaml) for loading yaml files
* [cloneextend](https://github.com/shimondoodkin/nodejs-clone-extend)

### Optional (for development)

* [grunt-cli](http://gruntjs.com)
* [node-inspector](https://github.com/dannycoates/node-inspector)

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

## Dynamic Token Replacement

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

###Example explained

The url regex `^/account/(\d{5})/category/([a-zA-Z]+)` has two defined capturing groups: `(\d{5})` and `([a-zA-Z]+)`, query regex has one defined capturing group `([a-zA-Z]+)`. In other words, a manually defined capturing group has parenthesis around it.

Although, the headers regex does not have capturing groups defined explicitly (no regex sections within parenthesis), its matched value is still accessible in a template (keep on reading!).

###Token structure

The tokens in response body follow the format of `< %PROPERTY_NAME[CAPTURING_GROUP_ID] %>`. If it is a token that should correspond to headers or query regex match, then the token structure would be as follows: `<% HEADERS_OR_QUERY.[KEY_NAME][CAPTURING_GROUP_ID] %>.

###Numbering the tokens based on capturing groups without sub-groups

When giving tokens their ID based on the count of manually defined capturing groups within regex, you should start from `1`, not zero (zero reserved for token that holds __full__ regex match) from left to right. So the leftmost capturing group would be `1` and the next one to the right of it would be `2`, etc.

In other words `<% url[1] %>` and `<% url[2] %>` tokens correspond to two capturing groups from the url regex `(\d{5})` and `([a-zA-Z]+)`, while `<% query.date[1] %>` token corresponds to one capturing group `([a-zA-Z]+)` from the `query` `date` property regex.

###Numbering the tokens based on capturing groups with sub-groups

In regex world, capturing groups can contain capturing sub-groups, as an example consider proposed `url` regex: `^/resource/(([a-z]{3})-([0-9]{3}))$`. In the latter example, the regex has three groups - a parent group `([a-z]{3}-[0-9]{3})` and two sub-groups within: `([a-z]{3})` & `([0-9]{3})`.

When giving tokens their ID based on the count of capturing groups, you should start from 1, not zero (zero reserved for token that holds __full__ regex match) from left to right. If a group has sub-group within, you count the sub-group(s) first (also from left to right) before counting the next one to the right of the parent group.

In other words tokens `<% url[1] %>`, `<% url[2] %>` and `<% url[3] %>` correspond to the three capturing groups from the url regex (starting from left to right): `([a-z]{3}-[0-9]{3})`, `([a-z]{3})` and `([0-9]{3})`.

###Tokens with ID zero

Tokens with ID zero can obtain `full` match value from the regex they reference. In other words, tokens with ID zero do not care whether regex has capturing groups defined or not. For example, token `<% url[0] %>` will be replaced with the `url` __full__ regex match from `^/account/(\d{5})/category/([a-zA-Z]+)`. So if you want to access the `url` __full__ regex match, respectively you would use token `<% url[0] %>` in your template.

Another example, would be the earlier case where `headers` `custom-header` property regex does not have capturing groups defined within. Which is fine, since the `<% headers.custom-header[0] %>` token corresponds to the __full__ regex match in the `header` `custom-header` property regex: `[0-9]+`.

It is also worth to mention, that the __full__ regex match value replacing token `<% query.date[0] %>`, would be equal to the regex capturing group value replacing `<% query.date[1] %>`. This is due to how the `query` `date` property regex is defined - the one and only capturing group in the query date regex, is also the __full__ regex itself.

###Where to specify the template

You can specify template with tokens in both `body` as a string or using `file` by specifying template as external local file. When template is specified as `file`, the contents of local file from `file` will be replaced, __not__ the path to local file defined in `file`.

###When token interpolation happens

After successful HTTP request verification, if your body or contents of local file from file contain tokens - the tokens will be replaced just before rendering HTTP response.

### Troubleshooting

* Make sure that the regex you used in your stubby configuration actually does what it suppose to do. Validate that it works before using it in stubby
* Make sure that the regex has capturing groups for the parts of regex you want to capture as token values. In other words, make sure that you did not forget the parenthesis within your regex if your token IDs start from `1`
* Make sure that you are using token ID zero, when wanting to use __full__ regex match as the token value
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

## Running Tests

If you don't have `grunt-cli` already, install it:

    npm install -g grunt-cli
    npm install

From the root directory run:

    grunt test

## Contributing

Fork, modify, request a pull. If changes are significant or touch more than one
part of the system, tests are suggested.

If large pull requests do not have tests there may be some push back until
functionality can be verified :)

## See Also

* **[stubby4j](https://github.com/azagniotov/stubby4j):** A java implementation of stubby
* **[stubby4net](https://github.com/mrak/stubby4net):** A .NET implementation of stubby
* **[grunt-stubby](https://github.com/h2non/grunt-stubby):** grunt integration with stubby
* **[gulp-stubby-server](https://github.com/felixzapata/gulp-stubby-server):** gulp integration with stubby

## TODO

* `post` parameter as a hashmap under `request` for easy form-submission value matching

## NOTES

* __Copyright__ 2014 Eric Mrak, Alexander Zagniotov
* __License__ Apache v2.0
