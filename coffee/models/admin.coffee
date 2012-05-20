http = require 'http'
qs = require 'querystring'
Request = require('./request').Request

Admin = module.exports.Admin = () ->
   goPUT = (request, response, signature) ->
      post = ''
      signature =
         method : request.method
         url : request.url

      request.on 'data', (data) ->
         post += data

      request.on 'end', () ->
         if post
            signature.post = qs.parse post

      newRequest = Request signature
      response.writeHead 204, {"Content-Type": "application/json"}
      response.end()

   goPOST = (request, response, signature) ->
      post = ''
      signature =
         method : request.method
         url : request.url

      request.on 'data', (data) ->
         post += data

      request.on 'end', () ->
         if post
            signature.post = qs.parse post

      newRequest = Request signature

      response.writeHead 201, {"Content-Type": "application/json"}
      response.write JSON.stringify(signature)
      response.end()

   goDELETE = (request, response) ->
      response.writeHead 204, {"Content-Type": "application/json"}
      response.end()

   goGET = (request, response) ->
      response.writeHead 200, {"Content-Type": "application/json"}
      response.end()

   go405 = (request, response) ->
      response.writeHead 405, {
         "Content-Type": "text/plain",
         "Allow" : "GET, POST, PUT, DELETE, OPTIONS"
         "Content-Length" : 0
      }
      response.end()

   urlValid = (request, response) ->
      valid = request.url.match /^\/[a-zA-Z0-9]*$/
      if not valid
         response.writeHead 404, {"Content-Type": "text/plain"}
         response.end()
      return valid


   return {
      server : http.createServer (request, response) ->
         if urlValid request, response
            switch request.method
               when 'PUT' then goPUT request, response
               when 'POST' then goPOST request, response
               when 'DELETE' then goDELETE request, response
               when 'GET' then goGET request, response
               else go405 request, response
   }
