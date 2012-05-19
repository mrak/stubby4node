http = require 'http'
mongo = require 'mongodb'
qs = require 'querystring'

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

admin = http.createServer (request, response) ->
   if request.method isnt 'POST'
      response.writeHead 405, {"Content-Type": "text/plain"}
      response.write 'Only POST requests are accepted'
      response.end()

   response.writeHead 200, {"Content-Type": "application/json"}

   signature =
      method : request.method
      url : request.url
   post = ''

   request.on 'data', (data) ->
      post += data

   request.on 'end', () ->
      if post
         signature.post = qs.parse post

      response.write JSON.stringify(signature)
      response.end()

admin.listen adminport
