http = require 'http'
Admin = require('./servers/admin').Admin
Stub = require('./servers/stub').Stub

stubport = 80
adminport = 81

stubServer = http.createServer Stub().server
stubServer.listen stubport

adminServer = http.createServer Admin().server
adminServer.listen adminport
