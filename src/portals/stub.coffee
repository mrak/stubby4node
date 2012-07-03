module.exports.Stub = class Stub
   constructor : (rNr) ->
      @RnR = rNr

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
         success = (rNr) ->
            response.writeHead rNr.status, JSON.parse(rNr.headers)
            response.write rNr.content if rNr.content?
            response.end()
         error = ->
            response.writeHead 500, {}
            response.end()
         notFound = ->
            response.writeHead 404, {}
            response.end()

         rNr = @RnR.find criteria, success, error, notFound

