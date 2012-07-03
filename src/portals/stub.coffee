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
            debugger
            response.writeHead rNr.status, rNr.headers
            if typeof rNr.content is 'object' then rNr.content = JSON.stringify rNr.content
            response.write rNr.content if rNr.content?
            response.end()
         error = ->
            response.writeHead 500, {}
            response.end()
         notFound = ->
            response.writeHead 404, {}
            response.end()

         rNr = @RnR.find criteria, success, error, notFound

