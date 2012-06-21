yaml = require 'js-yaml'

module.exports.Admin = class Admin
   constructor : (endpoint) ->
      @Endpoint = endpoint
      @Contract = require('../models/Contract').Contract

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
      error = => @send.serverError response
      notFound = => @send.notFound response

      @Endpoint.delete id, success, error, notFound

   goGET : (request, response) =>
      id = @getId request.url
      success = (data) => @send.ok response, data
      error = => @send.serverError response
      notFound = => @send.notFound response
      noContent = => @send.noContent response

      if id
         @Endpoint.retrieve id, success, error, notFound
      else
         @Endpoint.gather success, error, noContent

   processPUT : (id, data, response) =>
      try
         data = JSON.parse data
      catch e
         return @send.badRequest response

      if not @Contract data then return @send.badRequest response

      success = => @send.noContent response
      error = => @send.serverError response
      notFound = => @send.notFound response

      @Endpoint.update id, data, success, error, notFound

   processPOST : (data, response, request) =>
      try
         data = JSON.parse data
      catch e
         return @send.badRequest response

      if not @Contract data then return @send.badRequest response

      success = (id) => @send.created response, request, id
      error = => @send.saveError response

      @Endpoint.create data, success, error

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
      if @urlValid request.url
         switch request.method.toUpperCase()
            when 'PUT'    then @goPUT request, response
            when 'POST'   then @goPOST request, response
            when 'DELETE' then @goDELETE request, response
            when 'GET'    then @goGET request, response
            else @send.notSupported response
      else
         @send.notFound response
