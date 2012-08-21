# Changelog

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
