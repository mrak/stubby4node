CLI = require('../cli')
Portal = require('./portal').Portal

module.exports.Stub = class Stub extends Portal
   constructor : (rNr) ->
      @RnR = rNr
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
         success = (rNr) =>
            response.writeHead rNr.status, rNr.headers
            if typeof rNr.body is 'object' then rNr.body = JSON.stringify rNr.body
            response.write rNr.body if rNr.body?
            response.end()
            CLI.success @getLogLine request
         error = =>
            response.writeHead 500, {}
            CLI.error "#{@getLogLine request} unexpectedly generated a server error"
            response.end()
         notFound = =>
            response.writeHead 404, {}
            response.end()
            CLI.warn "#{@getLogLine request} is not a registered endpoint"

         try
            rNr = @RnR.find criteria, success, notFound
         catch e
            error()

