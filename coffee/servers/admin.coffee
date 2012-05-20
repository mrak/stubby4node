http = require 'http'
qs = require 'querystring'
Request = require('../models/request').Request

Admin = module.exports.Admin = () ->
   me = {
      goPUT : (request, response, signature) ->
         post = ''
         signature =
            method : request.method
            url : request.url

         request.on 'data', (data) ->
            post += data

         request.on 'end', () ->
            if post
               signature.post = qs.parse post

         newRequest = Request signature
         response.writeHead 204, {}
         response.end()

      goPOST : (request, response, signature) ->
         post = ''
         signature =
            method : request.method
            url : request.url

         request.on 'data', (data) ->
            post += data

         request.on 'end', () ->
            if post
               signature.post = qs.parse post

         newRequest = Request signature

         response.writeHead 201, {
            'Content-Location' : "#{request.headers.host}/#{newRequest._id}"
         }
         response.end()

      goDELETE : (request, response) ->
         response.writeHead 204, {}
         response.end()

      goGET : (request, response) ->
         response.writeHead 200, {'Content-Type': 'application/json'}
         response.write JSON.stringify(request.headers)
         response.end()

      sendNotSupported : (response) ->
         response.writeHead 405, {
            'Content-Type': 'text/plain'
            'Allow' : 'GET, POST, PUT, DELETE, OPTIONS'
            'Content-Length' : 0
         }
         response.end()

      sendNotFound : (response) ->
         response.writeHead 404, {'Content-Type': 'text/plain'}
         response.end()

      urlValid : (url) ->
         return url.match /^\/[a-f0-9]*$/

      server : (request, response) ->
         if me.urlValid request.url
            switch request.method
               when 'PUT'    then me.goPUT request, response
               when 'POST'   then me.goPOST request, response
               when 'DELETE' then me.goDELETE request, response
               when 'GET'    then me.goGET request, response
               else me.sendNotSupported response
         else
            me.sendNotFound response
   }
