Portal = require('./portal').Portal
qs = require 'querystring'

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
            url : extractUrl request.url
            method : request.method
            post : data
            headers : request.headers
            query : extractQuery request.url

         callback = (err, endpointResponse) =>
            if err
               @writeHead response, 404, {}
               @responded 404, request.url, 'is not a registered endpoint'
            else
               @writeHead response, endpointResponse.status, endpointResponse.headers
               response.write endpointResponse.body

               @responded endpointResponse.status, request.url
            response.end()

         try
            @Endpoints.find criteria, callback
         catch e
            response.statusCode =  500
            @responded 500, request.url, "unexpectedly generated a server error: #{e.message}"
            response.end()


extractUrl = (url) ->
   return url.replace /(.*)\?.*/, '$1'
extractQuery = (url) ->
   return qs.parse(url.replace /^.*\?(.*)$/, '$1')
