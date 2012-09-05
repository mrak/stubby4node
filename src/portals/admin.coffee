contract = require '../models/contract'
Portal = require('./portal').Portal
CLI = require '../cli'

module.exports.Admin = class Admin extends Portal
   constructor : (endpoints) ->
      @endpoints = endpoints
      @contract = contract
      @name = '[admin]'

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

      callback = (err) =>
         if err then return @send.notFound response
         @send.noContent  response

      @endpoints.delete id, callback

   goGET : (request, response) =>
      id = @getId request.url

      if id
         callback = (err, endpoint) =>
            if err then return @send.notFound response
            @send.ok response, endpoint
         @endpoints.retrieve id, callback
      else
         callback = (data) =>
            if data.length is 0 then return @send.noContent response
            @send.ok response, data
         @endpoints.gather callback

   processPUT : (id, data, response) =>
      try
         data = JSON.parse data
      catch e
         return @send.badRequest response

      if not @contract data then return @send.badRequest response

      callback = (err) =>
         if err then return @send.notFound response
         @send.noContent response

      @endpoints.update id, data, callback

   processPOST : (data, response, request) =>
      try
         data = JSON.parse data
      catch e
         return @send.badRequest response

      if not @contract data then return @send.badRequest response

      callback = (err, endpoint) => @send.created response, request, endpoint.id

      @endpoints.create data, callback

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

      badRequest : (response) ->
         response.writeHead 400, {'Content-Type' : 'text/plain'}
         response.end()

      notSupported : (response) ->
         response.writeHead 405, {}
         response.end()

      notFound : (response) ->
         response.writeHead 404, {'Content-Type' : 'text/plain'}
         response.end()

      saveError : (response) ->
         response.writeHead 422, {'Content-Type' : 'text/plain'}
         response.end()

      serverError : (response) ->
         response.writeHead 500, {'Content-Type' : 'text/plain'}
         response.end()

   urlValid : (url) ->
      return url.match(@urlPattern)?

   getId : (url) ->
      return url.replace @urlPattern, '$1'

   server : (request, response) =>
      CLI.info @getLogLine request

      if @urlValid request.url
         switch request.method.toUpperCase()
            when 'PUT'    then @goPUT request, response
            when 'POST'   then @goPOST request, response
            when 'DELETE' then @goDELETE request, response
            when 'GET'    then @goGET request, response
            else @send.notSupported response
      else
         @send.notFound response
