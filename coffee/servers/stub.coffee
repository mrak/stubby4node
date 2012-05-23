RnR = require('../models/requestresponse').RequestResponse

module.exports.Stub = class Stub
   constructor : ->
      @RnR = new RnR()
      @qs = require 'querystring'

   server : (request, response) =>
      data = null
      request.on 'data', (chunk) ->
         data = data ? ''
         data += chunk

      request.on 'end', () =>
         criteria =
            url : request.url
            method : request.method
            post : data
         success = (rNr) ->
            response.writeHead rNr.status, JSON.parse(rNr.headers)
            response.write rNr.content
            response.end()
         error = ->
            response.writeHead 500, {}
            response.end()

         rNr = @RnR.find criteria, success, error

