contract = require '../models/contract'
Portal = require('./portal').Portal
CLI = require '../cli'
http = require 'http'

module.exports.Admin = class Admin extends Portal
   constructor : (endpoints, muted = false) ->
      CLI.mute  = muted
      @endpoints = endpoints
      @contract = contract
      @name = '[admin]'

   urlPattern : /^\/([1-9][0-9]*)?$/

   goPUT : (request, response) =>
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

   goDELETE : (request, response) =>
      id = @getId request.url
      if not id then return @notSupported response

      callback = (err) =>
         if err then return @notFound response
         @noContent  response

      @endpoints.delete id, callback

   goGET : (request, response) =>
      id = @getId request.url

      if id
         callback = (err, endpoint) =>
            if err then return @notFound response
            @ok response, endpoint
         @endpoints.retrieve id, callback
      else
         callback = (data) =>
            if data.length is 0 then return @noContent response
            @ok response, data
         @endpoints.gather callback

   processPUT : (id, data, response) =>
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

   processPOST : (data, response, request) =>
      try
         data = JSON.parse data
      catch e
         return @badRequest response

      errors = @contract data
      if errors then return @badRequest response, errors

      callback = (err, endpoint) => @created response, request, endpoint.id

      @endpoints.create data, callback

   ok : (response, result) =>
      response.writeHead 200, {'Content-Type' : 'application/json'}
      response.write JSON.stringify result
      response.end()
      @logResponse 200

   created : (response, request, id) =>
      response.writeHead 201, {'Location' : "#{request.headers.host}/#{id}"}
      response.end()
      @logResponse 201

   noContent : (response) =>
      response.writeHead 204, {}
      response.end()
      @logResponse 204

   badRequest : (response, errors) =>
      response.writeHead 400, {'Content-Type' : 'application/json'}
      response.write JSON.stringify errors
      response.end()
      @logResponse 400

   notSupported : (response) =>
      response.writeHead 405, {}
      response.end()
      @logResponse 405

   notFound : (response) =>
      response.writeHead 404, {'Content-Type' : 'text/plain'}
      response.end()
      @logResponse 404

   saveError : (response) =>
      response.writeHead 422, {'Content-Type' : 'text/plain'}
      response.end()
      @logResponse 422

   serverError : (response) =>
      response.writeHead 500, {'Content-Type' : 'text/plain'}
      response.end()
      @logResponse 500

   logResponse : (status) ->
      fn = 'log'
      switch
         when 600 > status >= 400
            fn = 'error'
         when status >= 300
            fn = 'warn'
         when status >= 200
            fn = 'success'
         when status >= 100
            fn = 'info'
      CLI[fn] @getResponseLogLine status, " #{http.STATUS_CODES[status]}"


   urlValid : (url) ->
      return url.match(@urlPattern)?

   getId : (url) ->
      return url.replace @urlPattern, '$1'

   server : (request, response) =>
      CLI.say @getLogLine request

      if @urlValid request.url
         switch request.method.toUpperCase()
            when 'PUT'    then @goPUT request, response
            when 'POST'   then @goPOST request, response
            when 'DELETE' then @goDELETE request, response
            when 'GET'    then @goGET request, response
            else @notSupported response
      else
         @notFound response
