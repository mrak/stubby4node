CLI = require('../cli')
Portal = require('./portal').Portal

module.exports.Stub = class Stub extends Portal
   constructor : (endpoints) ->
      @Endpoints = endpoints
      @name = '[stub]'

   server : (request, response) =>
      data = null
      request.on 'data', (chunk) ->
         data = data ? ''
         data += chunk

      request.on 'end', =>
         criteria =
            url : request.url
            method : request.method
            post : data
         callback = (err, rNr) =>
            if err
               response.writeHead 404, {}
               response.end()
               CLI.warn "#{@getLogLine request} is not a registered endpoint"
            else
               response.writeHead rNr.status, rNr.headers
               if typeof rNr.body is 'object' then rNr.body = JSON.stringify rNr.body
               response.write rNr.body if rNr.body?
               response.end()
               CLI.success @getLogLine request

         try
            @Endpoints.find criteria, callback
         catch e
            @fault request, response
