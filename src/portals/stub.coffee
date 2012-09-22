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
         CLI.say @getLogLine request
         criteria =
            url : request.url
            method : request.method
            post : data
         callback = (err, rNr) =>
            if err
               response.writeHead 404, {}
               CLI.error "#{@getResponseLogLine 404, request.url} is not a registered endpoint"
            else
               response.writeHead rNr.status, rNr.headers
               if typeof rNr.body is 'object' then rNr.body = JSON.stringify rNr.body
               response.write rNr.body if rNr.body?
               fn = 'log'
               switch
                  when 600 > rNr.status >= 400
                     fn = 'error'
                  when rNr.status >= 300
                     fn = 'warn'
                  when rNr.status >= 200
                     fn = 'success'
                  when rNr.status >= 100
                     fn = 'info'
               CLI[fn] @getResponseLogLine rNr.status, request.url
            response.end()

         try
            @Endpoints.find criteria, callback
         catch e
            console.dir e
            @fault request, response
