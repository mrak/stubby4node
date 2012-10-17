Portal = require('./portal').Portal

module.exports.Stubs = class Stubs extends Portal
   constructor : (endpoints) ->
      @Endpoints = endpoints
      @name = '[stubs]'

   server : (request, response) =>
      data = null
      request.on 'data', (chunk) ->
         data = data ? ''
         data += chunk

      request.on 'end', =>
         @received request, response
         criteria =
            url : request.url
            method : request.method
            post : data
         callback = (err, endpointResponse) =>
            if err
               response.writeHead 404, {}
               @responded 404, request.url, 'is not a registered endpoint'
            else
               response.writeHead endpointResponse.status, endpointResponse.headers
               if typeof endpointResponse.body is 'object' 
                  endpointResponse.body = JSON.stringify endpointResponse.body
               response.write endpointResponse.body if endpointResponse.body?
               @responded endpointResponse.status, request.url
            response.end()

         try
            @Endpoints.find criteria, callback
         catch e
            response.statusCode =  500
            @responded 500, request.url, "unexpectedly generated a server error"
            response.end()
