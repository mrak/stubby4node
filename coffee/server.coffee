http = require 'http'
Admin = require('./servers/admin').Admin
Stub = require('./servers/stub').Stub

stubport = 80
adminport = 81

stubServer = (new Stub()).server
http.createServer(stubServer).listen stubport

adminServer  = (new Admin()).server
http.createServer(adminServer).listen adminport
