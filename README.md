# Node Stub Server

A configurable server for mocking/stubbing external systems during development. Uses Node.js and SQLite3. Written in Coffeescript

## Requirements

* node.js (build with v0.6.15)
* sqlite3
* coffeescript

### Optionals (for Guard)

* ruby
* bundler

### More Optionals (for debugging)

* node-inspector

## Installation

    git clone git://github.com/Afmrak/node-stub-server.git <project-directory>

    cd <project-directory>

    npm install sqlite3

    npm install -g coffee-script

    coffee --compile --output js coffee

### To have Guard automagically compile your coffeescripts as they are edited (assuming ruby and bundler installed)

    bundle install

    bundle exec guard

## Starting the Server(s)

Some systems require you to `sudo` before running services on port 80

`[sudo] node js/server.js`

## The Admin Portal

The admin portal is a RESTful endpoint running on `localhost:81`.

### Creating a Stubbed Response

Submit `POST` requests to `localhost:81` with the following six POST parameters:

* **url**: the url you want the stub server to respond to. Include exact `GET` parameters here
* **method**: POST, GET, PUT, DELETE, etc.
* **post**: the textual post data, either plain text or in query-string format that is required for the response you are stubbing
* **headers**: a JSON string containing key/value pairings of any header fields the server should respond to the given url with
* **status**: the HTTP 1.1 status code the response should use (i.e. 200)
* **content**: the content body of the response. JSON, HTML, whatever as a string

On success, the response with contain `Content-Location : localhost/<id>` in the header for future reference

### GET the Current List of Stubbed Responses

Performing a `GET` request on `localhost:81` will return a JSON array of all currently saved responses. It will reply with `204 : No Content` if there are none saved.

Performing a `GET` request on `localhost:81/<id>` will return the JSON object representing the response with the supplied id.

### Change existing responses

Perform `PUT` requests in the same format as using `POST`, only this time supply the id. For instance, to update the response with id 4 you would `PUT` to `localhost:81/4`.

### Deleting responses

Send a `DELETE` request to `localhost:81/<id>`

## The Stub Portal

Requests sent to any url at `localhost` or `localhost:80` will respond with the configured headers, status code, and content given that the request url, method and post data matches. Otherwise, it will return a `404 : Not Found`

## TODO

* `PUT`ing and `POST`ing multiple responses at a time.
* Ability to set up responses via JSON
* configurable ports via command-line
