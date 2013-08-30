contract = require '../models/contract'
Portal = require('./portal').Portal
http = require 'http'
ns = require 'node-static'
path = require 'path'
status = new ns.Server (path.resolve __dirname, '../../webroot')

module.exports.Admin = class Admin extends Portal

   constructor : (endpoints) ->
      @endpoints = endpoints
      @contract = contract
      @name = '[admin]'

   urlPattern : /^\/([1-9][0-9]*)?$/

   goPong: (response) ->
      @writeHead response, 200, {'Content-Type' : 'text/plain'}
      response.end 'pong'

   goPUT : (request, response) ->
      id = @getId request.url
      if not id
         @notSupported response
         return

      data = ''
      request.on 'data', (chunk) ->
         data += chunk

      request.on 'end', => @processPUT id, data, response

   goPOST : (request, response) ->
      id = @getId request.url
      if id then return @notSupported response

      data = ''
      request.on 'data', (chunk) ->
         data += chunk

      request.on 'end', => @processPOST data, response, request

   goDELETE : (request, response) ->
      id = @getId request.url
      if not id then return @notSupported response

      callback = (err) =>
         if err then return @notFound response
         @noContent  response

      @endpoints.delete id, callback

   goGET : (request, response) ->
      id = @getId request.url

      if id
         callback = (err, endpoint) =>
            if err then return @notFound response
            @ok response, endpoint
         @endpoints.retrieve id, callback
      else
         callback = (err, data) =>
            if data.length is 0 then return @noContent response
            @ok response, data
         @endpoints.gather callback

   processPUT : (id, data, response) ->
      try
         data = JSON.parse data
      catch e
         return @badRequest response

      errors = @contract data
      if errors then return @badRequest response, errors

      callback = (err) =>
         if err then return @notFound response
         @noContent response

      @endpoints.update id, data, callback

   processPOST : (data, response, request) ->
      try
         data = JSON.parse data
      catch e
         return @badRequest response

      errors = @contract data
      if errors then return @badRequest response, errors

      callback = (err, endpoint) => @created response, request, endpoint.id

      @endpoints.create data, callback

   ok : (response, result) ->
      @writeHead response, 200, {'Content-Type' : 'application/json'}
      if result?
         response.end(JSON.stringify result)
      else
         response.end()

   created : (response, request, id) ->
      @writeHead response, 201, {'Location' : "#{request.headers.host}/#{id}"}
      response.end()

   noContent : (response) ->
      response.statusCode = 204
      response.end()

   badRequest : (response, errors) ->
      @writeHead response, 400, {'Content-Type' : 'application/json'}
      response.end JSON.stringify errors

   notSupported : (response) ->
      response.statusCode = 405
      response.end()

   notFound : (response) ->
      @writeHead response, 404, {'Content-Type' : 'text/plain'}
      response.end()

   saveError : (response) ->
      @writeHead response, 422, {'Content-Type' : 'text/plain'}
      response.end()

   serverError : (response) ->
      @writeHead response, 500, {'Content-Type' : 'text/plain'}
      response.end()

   urlValid : (url) ->
      return url.match(@urlPattern)?

   getId : (url) ->
      return url.replace @urlPattern, '$1'

   server : (request, response) =>
      @received request, response
      response.on 'finish', => @responded response.statusCode, request.url

      if request.url is '/ping'
         return @goPong response

      if /^\/(status|js|css)(\/.*)?$/.test request.url
         return status.serve request, response

      if @urlValid request.url
         switch request.method.toUpperCase()
            when 'PUT'    then @goPUT request, response
            when 'POST'   then @goPOST request, response
            when 'DELETE' then @goDELETE request, response
            when 'GET'    then @goGET request, response
            else @notSupported response
      else
         @notFound response

