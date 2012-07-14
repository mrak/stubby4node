Contract = require('../models/Contract').Contract
cli = new (require('../cli').CLI)()

exports.Admin = class Admin
   constructor : (endpoint) ->
      @Endpoint = endpoint
      @Contract = Contract

   urlPattern : /^\/([1-9][0-9]*)?$/

   goPUT : (request, response) =>
      id = @getId request.url
      if not id
         @send.notSupported response
         return

      data = ''
      request.on 'data', (chunk) ->
         data += chunk

      request.on 'end', => @processPUT id, data, response

   goPOST : (request, response) ->
      id = @getId request.url
      if id then return @send.notSupported response

      data = ''
      request.on 'data', (chunk) ->
         data += chunk

      request.on 'end', => @processPOST data, response, request

   goDELETE : (request, response) =>
      id = @getId request.url
      if not id then return @send.notSupported response

      success = => @send.noContent response
      notFound = => @send.notFound response

      @Endpoint.delete id, success, notFound

   goGET : (request, response) =>
      id = @getId request.url
      success = (data) => @send.ok response, data
      notFound = => @send.notFound response
      noContent = => @send.noContent response

      if id
         @Endpoint.retrieve id, success, notFound
      else
         @Endpoint.gather success, noContent

   processPUT : (id, data, response) =>
      try
         data = JSON.parse data
      catch e
         return @send.badRequest response

      if not @Contract data then return @send.badRequest response

      success = => @send.noContent response
      notFound = => @send.notFound response

      @Endpoint.update id, data, success, notFound

   processPOST : (data, response, request) =>
      try
         data = JSON.parse data
      catch e
         return @send.badRequest response

      if not @Contract data then return @send.badRequest response

      success = (id) => @send.created response, request, id

      @Endpoint.create data, success

   send :
      ok : (response, result) ->
         response.writeHead 200, {'Content-Type' : 'application/json'}
         response.write JSON.stringify result
         response.end()

      created : (response, request, id) ->
         response.writeHead 201, {'Content-Location' : "#{request.headers.host}/#{id}"}
         response.end()

      noContent : (response) ->
         response.writeHead 204, {}
         response.end()

      notSupported : (response) ->
         response.writeHead 405, {}
         response.end()

      notFound : (response) ->
         response.writeHead 404, {'Content-Type' : 'text/plain'}
         response.end()

      serverError : (response) ->
         response.writeHead 500, {'Content-Type' : 'text/plain'}
         response.end()

      saveError : (response) ->
         response.writeHead 422, {'Content-Type' : 'text/plain'}
         response.end()

      badRequest : (response) ->
         response.writeHead 400, {'Content-Type' : 'text/plain'}
         response.end()

   urlValid : (url) ->
      return url.match(@urlPattern)?

   getId : (url) ->
      return url.replace @urlPattern, '$1'

   server : (request, response) =>
      date = new Date()
      hours = "0#{date.getHours()}".slice -2
      minutes = "0#{date.getMinutes()}".slice -2
      seconds = "0#{date.getSeconds()}".slice -2
      cli.info "#{hours}:#{minutes}:#{seconds} -> #{request.method} #{request.headers.host}#{request.url}"

      if @urlValid request.url
         switch request.method.toUpperCase()
            when 'PUT'    then @goPUT request, response
            when 'POST'   then @goPOST request, response
            when 'DELETE' then @goDELETE request, response
            when 'GET'    then @goGET request, response
            else @send.notSupported response
      else
         @send.notFound response
