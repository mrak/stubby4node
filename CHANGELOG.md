# Changelog

## 0.1.34

* added "query" parameter for "request" objects to allow comparison by variable instead of static querystring

## 0.1.33

* fixed severe issue where request headers were not being matched by the stubs portal
* renamed "stub" option to "stubs"
* __NEW__: request.file can be used to specify a file whose contents will be used as the response body. If the file cannot be found, it falls back to whatever was specified in response.body

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
