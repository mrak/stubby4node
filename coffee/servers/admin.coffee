mongo = require 'mongodb'
server = new mongo.Server 'localhost', 27017, {auto_reconnect : true}

Admin = module.exports.Admin = () ->
   me = {
      qs: require 'querystring'

      db: new mongo.Db 'stubserver', server

      RnR: require('../models/requestresponse').RequestResponse()

      goPUT : (request, response) ->
         post = ''
         signature =
            method : request.method
            url : request.url

         request.on 'data', (data) ->
            post += data

         request.on 'end', () ->
            if post
               signature.post = me.qs.parse post

         newRnR = me.RnR signature
         response.writeHead 204, {}
         response.end()

      goPOST : (request, response) ->
         data = ''
         request.on 'data', (chunk) ->
            data += chunk

         request.on 'end', () ->
            data = me.qs.parse data
            rNr = me.RnR.create data

            me.db.open (err, db) ->
               if not err
                  db.collection 'rnr', (err, collection) ->
                     if not err
                        collection.insert rNr, {safe:true}, (err, result) ->
                           if not err
                              response.writeHead 201, {
                                 'Content-Location' : "#{request.headers.host}/#{rNr._id}"
                              }
                              response.end()
                           else
                              me.sendSaveError()
                     else
                        me.sendServerError()
               else
                  me.sendServerError()



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

      sendServerError : () ->
         response.writeHead 500, {'Content-Type':'text/plain'}
         response.end()

      sendSaveError : () ->
         response.writeHead 507, {'Content-Type':'text/plain'}
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
