http = require("http")

stub = http.createServer (request, response) ->
   response.writeHead 200, {"Content-Type": "text/plain"}
   response.write "Hello World"
   response.end()

stub.listen 80

admin = http.createServer (request, response) ->
   response.writeHead 200, {"Content-Type": "text/plain"}
   response.write "Hello Admin"
   response.end()

admin.listen 81
