http = require 'http'
Admin = require('./servers/admin').Admin
mongo = require 'mongodb'

stubport = 80
adminport = 81
mongohost = 'localhost'
mongoport = mongo.Connection.DEFAULT_PORT

db = new mongo.Db 'stubserver', new mongo.Server(mongohost, mongoport, {}), {}
db.open(() -> {})

stub = http.createServer (request, response) ->
   response.writeHead 200, {"Content-Type": "application/json"}
   response.write '{"message":"Hello World"}'
   response.end()

stub.listen stubport

adminServer = http.createServer Admin().server
adminServer.listen adminport
