http = require 'http'
Admin = require('./servers/admin').Admin

stubport = 80
adminport = 81

stub = http.createServer (request, response) ->
   response.writeHead 200, {"Content-Type": "text/plain"}
   response.write 'nothing implemented yet'
   response.end()

stub.listen stubport

adminServer = http.createServer Admin().server
adminServer.listen adminport
