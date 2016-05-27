# Changelog

## 0.3.1

* Fixes `path` errors in Node 6

## 0.3.0

* __BREAKING CHANGES from 0.2.x__
  * In `0.2.x` and below, you could pass `request.headers.authorization` as a `username:password` string to signify Basic auth and stubby would automatically prefix `Basic ` and base64-encode the user/pass string. This breaks other forms of web auth that uses the `Authorization` header.
  ```yaml
  # Before
  request:
    headers:
      authorization: 'username:password'
  # Now
  request:
    headers:
      authorization: 'Basic username:password'
  ```
  Stubby will still base64-encode the `username:password` if it sees that `Basic ` is specified and the `:` character is present. Otherwise it will take it as-is.
* __New features__
  * `json:` option for endpoints -- instead of using `post:` or `file:` for matching the body of incoming requests, you can specify `json: ` with a JSON string and its content will be deeply matched for incoming request bodies.

## 0.2.13

* fixes a crash when using `start()` without any options

## 0.2.12

* fixes array representations in query strings

## 0.2.11

* fixes several scope-binding issues caused by the JavaScript rewrite (sorry!)
* clarify use of `PUT` and the admin portal
* added `_httpsOptions` to pass through options to the underlying tls server.

## 0.2.10

* fix colorsafe console wrapper errors (Esco Obong)

## 0.2.9

* Rewrote library in JavaScript (was CoffeeScript)

## 0.2.8

* fixes the status page display (Hadi Michael)

## 0.2.7

* fixes unhelpful output when the location given cannot be bound to

## 0.2.6

* fixes an issue where identical URLs with different request methods may throw
  an exception

## 0.2.5

* token replacement from regex capture groups is now usable for dynamic `file:`
  usage

## 0.2.3

* added recording feature. If a `response` object uses a string in place of an object (or a sequence of objects/string) the strings will be interpreted as a url to record the response from. Details configured in the `request` object (such as `method`, `headers`, etc) will be used to make the recording request to the specified url
* improved CORS compliance with request/response headers
* added dynamic templating features for interpolating data captured in request regular expressions into response strings

## 0.2.2

* CORS compliance as per W3C specifications. Using `*` as the `--location` will instruct stubby to listen on all interfaces. Implemented by [Tomás Aparicio](https://github.com/h2non)

## 0.2.1

* bugfix for "Could not render headers to client" from `h2non`

## 0.2.0

* added cyclic responses. `response` can now be a yaml sequence of responses. Backward compatible, thus the minor version bump
* all string values for `response` criteria are matched as regular expressions against the incoming request

## 0.1.50

* bugfix: admin and programmatic APIs correctly parse incoming data

## 0.1.49

* updating styling of status page.

## 0.1.48

* fixed a bug with the latest version of node where status page was no longer showing.

## 0.1.47

* urls are now matched via regular expressions. If you want an exact match, remember to prefix your urls with `^` and postfix with `$`

## 0.1.46

* binary data files are working correctly when used as a response body
* fixed a bug were stubby's version number was appearing as `undefined` in the `Server` header

## 0.1.45

* fixed a bug involving recursive use of `process.nextTick`

## 0.1.44

* line endings are normalized to `\n` and trailing whitespace is trimmed from the end when matching request's post/file contents

## 0.1.43

* `response.file` and `request.file` are now relative paths from the root data.yaml instead of being relative from the source of execution

## 0.1.42

* `request.headers.authorization` can now take values such as `username:password` which will automatically be converted to `Basic dXNlcm5hbWU6cGFzc3dvcmQ=`.
* parameterized flags can now be combined with non-parameterized flags. Example: `-dw data.yaml` is equivalent to `--watch --data data.yaml`.
* switched from handlebars to underscore for client-side templating

## 0.1.41

* added `PATCH` to acceptable HTTP verbs.
* bugfix where `--watch` flag was always active.
* added `man` page support

## 0.1.40

* bugfixes related to command line parsing
* fixed bug where query params were not being saved
* added `status` endpoint on admin portal.

## 0.1.39

* main `stubby` module now correctly accepts all options availabel via the command line in it's first argument.
* added `-w, --watch` flag. Monitors the supplied `-d, --data` file for changes and reloads the file if necessary.
* for the `require('stubby')` module, a filename is passed as `options.watch` for the `start(options, callback)` function.

## 0.1.38

* made method definitions (`PUT`, `POST`, etc.) case insensitive. You could use `post`, `get`, etc. instead.
* made `response` object completely **optional**. Defaults to `200` status with an empty `body`.
* you can now specify an array of acceptible `method`s in your YAML:

```yaml
-  request:
      url: /anything
      method: [get, head]
```


## 0.1.37

* added /ping endpoint to admin portal

## 0.1.36

* running stubs portal at both http and https by default
* addition of `-t, --tls` option to specifying https port for stubs portal

## 0.1.35

* added `file` parameter to `request` object. When matching a request, if it has `file` specified it will load it's contents from the filesystem as the `post` value. If the `file` cannot be found, it falls back to `post`.

## 0.1.34

* added `query` parameter for `request` objects to allow comparison by variable instead of static querystring

## 0.1.33

* fixed severe issue where request headers were not being matched by the stubs portal
* renamed "stub" option to "stubs"
* __NEW__: `request.file` can be used to specify a file whose contents will be used as the response body. If the file cannot be found, it falls back to whatever was specified in `response.body`

## 0.1.32

* stubby can now be muted

## 0.1.31

* removed coffee-script as a dependency
* errors and warnings for missing or unparsable data files have been improved
* re-write of code operating the command-line interface

## 0.1.30

* admin portal console logging for responses
* reworked API contract failures for admin portal. Upon BAD REQUEST server returns an array of errors describing the endpoint validations that were violated.

## 0.1.29

* logging messages fixes for stub portal

## 0.1.28

* fixed callback parameters for stubby interface

## 0.1.27

* you can now make as many instances of stubby as you want by: require("stubby").Stubby and var stubby = new Stubby()

## 0.1.26

* callbacks now give copies of endoints instead of refernces. This prevents unexpected changes to endpoints outside of stubby

## 0.1.25

* bug fixes. optional dependency js-yaml is now *really* optional

## 0.1.24

* serval bugs fixed that were found while experimenting with a main module

## 0.1.23beta

* fixed but with endpoints with undefined headers not being accepted

## 0.1.22beta

* added -k, --key and -c, --cert and -p, -pfx options for stating stubby as an https server
* retired -f, --file option in lieu of -d, --data to prevent confusion between suppling files for data files versus ssl key/certificate files


## 0.1.21beta

* added -l flag for starting stubby at a particular address

## 0.1.20beta

* added -v --version command line option

## 0.1.19beta

* gracefully exits on error when starting stubby

## 0.1.17beta

* removed node-inspector as a dependency
* removed jasmine-node as a dependency

## 0.1.16beta

* default stub portal is now 8882 (from 80)
* default admin portal is now 8889 (from 81)

## 0.1.15beta

* initial release
