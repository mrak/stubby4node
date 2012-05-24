http = require 'http'
Admin = require('./servers/admin').Admin
Stub = require('./servers/stub').Stub
RnR = require('./models/requestresponse').RequestResponse
rNr = new RnR()

stubport = 80
adminport = 81

stubServer = (new Stub(rNr)).server
http.createServer(stubServer).listen stubport

adminServer  = (new Admin(rNr)).server
http.createServer(adminServer).listen adminport
