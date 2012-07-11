cli = new (require('../cli').CLI)()

exports.Stub = class Stub
   constructor : (rNr) ->
      @RnR = rNr

   server : (request, response) =>
      date = new Date()
      hours = "0#{date.getHours()}".slice -2
      minutes = "0#{date.getMinutes()}".slice -2
      seconds = "0#{date.getSeconds()}".slice -2
      outputMsg = "#{hours}:#{minutes}:#{seconds} -> #{request.method} #{request.url}"

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
            response.writeHead rNr.status, rNr.headers
            if typeof rNr.content is 'object' then rNr.content = JSON.stringify rNr.content
            response.write rNr.content if rNr.content?
            response.end()
            cli.success outputMsg
         error = ->
            response.writeHead 500, {}
            cli.error "#{outputMsg} unexpectedly generated a server error"
            response.end()
         notFound = ->
            response.writeHead 404, {}
            response.end()
            cli.warn "#{outputMsg} is not a registered endpoint"

         try
            rNr = @RnR.find criteria, success, notFound
         catch e
            error()

