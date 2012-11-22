# Endpoints

This doc explains the usage, intent and behavior of each property on the `request` and `response` objects.

Here is a fully-populated, unrealistic endpoint:
```yaml
-  request:
      url: /your/awesome/endpoint
      method: POST
      query:
         exclamation: post%20requests%20can%20have%20query%20strings%21
      headers:
         content-type: application/xml
      post: >
         <!xml blah="blah blah blah">
         <envelope>
            <unaryTag/>
         </envelope>
      file: tryMyFirst.xml
   response:
      status: 200
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
```

## request

This object is used to match an incoming request to stubby against the available endpoints that have been configured.

### url (required)

* This is the only required property of an endpoint.
* signify the url after the base host and port (i.e. after `localhost:8882`).
* must begin with ` / `.
* any query paramters are stripped (so don't include them, that's what `query` is for).
    * `/url?some=value&another=value` becomes `/url`
* no checking is done for URI-encoding compliance.
    * If it's invalid, it won't ever trigger a match.

This is the simplest you can get:
```yaml
-  request:
      url: /
```

### method

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
      url: /yonder
      method:
         -  GET
         -  HEAD
         -  POST
```

### query

* if ommitted, stubby ignores query parameters for the given url.
* a yaml hashmap of variable/value pairs.
* allows the query parameters to appear in any order in a uri

* The following will match either of these:
    * `/with/parameters?search=search+terms&filter=month`
    * `/with/parameters?filter=month&search=search+terms`

```yaml
-  request:
      url: /with/parameters
      query:
         search: search+terms
         filter: month
```

### post

* if ommitted, any post data is ignored.
* the body contents of the server request, such as form data.

```yaml
-  request:
      url: /post/form/data
      post: name=John&email=john@example.com
```

### file

* if supplied, replaces `post` with the contents of the locally given file.
    * paths are relative from where stubby was executed.
* if the file is not found when the request is made, falls back to `post` for matching.
* allows you to split up stubby data across multiple files

```yaml
-  request:
      url: /match/against/file
      file: postedData.json
      post: '{"fallback":"data"}'
```

postedData.json
```json
{"fileContents":"match against this if the file is here"}
```

* if `postedData.json` doesn't exist on the filesystem when `/match/against/file` is requested, stubby will match post contents against `{"fallback":"data"}` (from `post`) instead.

### headers

* if ommitted, stubby ignores headers for the given url.
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

## response

Assuming a match has been made against the given `request` object, data from `response` is used to build the stubbed response back to the client.

### status

* the HTTP status code of the response.
* integer or integer-like string.
* defaults to `200`.

```yaml
-  request:
      url: /im/a/teapot
      method: POST
   response:
      status: 420
```

### body

* contents of the response body
* defaults to an empty content body

```yaml
-  request:
      url: /give/me/a/smile
   response:
      body: ':)'
```

### file

* similar to `request.file`, but the contents of the file are used as the `body`.

```yaml
-  request:
      url: /
   response:
      file: extremelyLongJsonFile.json
```

### headers

* similar to `request.headers` except that these are sent back to the client.

```yaml
-  request:
      url: /give/me/some/json
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

### latency

* time to wait, in milliseconds, before sending back the response
* good for testing timeouts, or slow connections

```yaml
-  request:
      url: /hello/to/jupiter
   response:
      latency: 800000
      body: Hello, World!
```
