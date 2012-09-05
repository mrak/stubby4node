CLI = require('../cli')
Portal = require('./portal').Portal

module.exports.Stub = class Stub extends Portal
   constructor : (endpoints) ->
      @Endpoints = endpoints
      @name = '[stubs]'

   server : (request, response) =>
      data = null
      request.on 'data', (chunk) ->
         data = data ? ''
         data += chunk

      request.on 'end', =>
         CLI.success @getLogLine request
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
               switch
                  when rNr.status >= 500
                     CLI.error @getResponseLogLine rNr.status, request.url
                  when rNr.status >= 400
                     CLI.warn @getResponseLogLine rNr.status, request.url
                  else
                     CLI.success @getResponseLogLine rNr.status, request.url

         try
            @Endpoints.find criteria, callback
         catch e
            console.dir e
            @fault request, response
