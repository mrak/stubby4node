# Examples

## If <xyz> is ommitted...

* `ommited property`: outcome if property is left out.

* `request`: Required. Endpoint fails to load.
    * `url`: Required. Endpoint fails to load.
    * `query`: Any query paramters are acceptable.
    * `method`: Accepts `GET` requests.
    * `headers`: Accepts any headers.
* `response`: Required. Endpoint fails to load.
    * `status`: Responds with `200`.
    * `latency`: Zero latency is used.
    * `headers`: Default nodejs headers used.
    * `file`: Uses whatever is defined in `response.body`.
    * `body`: Response body is empty.

A `GET` request to the application root with an empty, `200` status code response.

```yaml
-  request:
      url: /
   response: {}
```

Same, but as a `HEAD` request.

```yaml
-  request:
      url: /
      method: HEAD
   response: {}
```

A `POST` request that only responds to form submissions.

```yaml
-  request:
      url: /
      method: POST
      headers:
         content-type: application/x-www-form-urlencoded
   response: {}
```

A `GET` request with at least `search` and `filter` parameters passed with the given values. Responds with `No data found!`.

```yaml
-  request:
      url: /query/me
      query:
         search: myHistory
         filter: highSchoolYears
   response:
      body: No data found!
```

A `GET` request that takes 15 seconds to respond.

```yaml
-  request:
      url: /slow/as/a/snail
   response:
      latency: 15000
```

A `GET` request that returns a file's contents (if found at requst time). Else, it returns some text.

```yaml
-  request:
      url: /gimme/my/file
   response:
      file: path/to/file.stuff
      body: File not found! Did you delete it?
```

A json `POST` request that returns xml.

```yaml
-  request:
      url: /json/for/xml
      headers:
         content-type: application/json
      post: >
         {
            "property": "value"
         }
   response:
      headers:
         content-type: text/xml
      body: >
         <?xml version="1.0" encoding="UTF-8"?>
         <root>
            <child/>
            <child/>
         </root>
```
