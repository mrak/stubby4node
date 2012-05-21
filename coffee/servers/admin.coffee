mongo = require 'mongodb'
server = new mongo.Server 'localhost', 27017, {auto_reconnect : true}
ObjectID = mongo.ObjectID

Admin = module.exports.Admin = () ->
   db = new mongo.Db 'stubserver', server
   db.open () -> {}

   me = {
      qs: require 'querystring'

      db: db

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

         response.writeHead 204, {}
         response.end()

      goPOST : (request, response) ->
         data = ''
         request.on 'data', (chunk) ->
            data += chunk

         request.on 'end', () ->
            data = me.qs.parse data
            rNr = me.RnR.create data

            db.collection 'rnr', (err, collection) ->
               if not err
                  collection.insert rNr, {safe:true}, (err, result) ->
                     if not err
                        response.writeHead 201, {
                           'Content-Location' : "#{request.headers.host}/#{rNr._id}"
                        }
                        response.end()
                     else
                        me.sendSaveError response
               else
                  me.sendServerError response

      goDELETE : (request, response) ->
         id = request.url.replace /^\/([a-f0-9]*)$/, '$1'

         db.collection 'rnr', (err, collection) ->
            if not err
               collection.remove {_id : new ObjectID id}, {safe : true}, (err, result) ->
                  if not err
                     if not result
                        me.sendNotFound response
                     else
                        response.writeHead 204, {}
                        response.end()
                  else
                     me.sendServerError response
            else
               me.sendServerError response

      goGET : (request, response) ->
         id = request.url.replace /^\/([a-f0-9]*)$/, '$1'

         db.collection 'rnr', (err, collection) ->
            if not err
               collection.findOne {_id : new ObjectID id}, (err, result) ->
                  if not err
                     if not result
                        me.sendNotFound response
                     else
                        response.writeHead 200, {}
                        response.write JSON.stringify result
                        response.end()
                  else
                     me.sendServerError response
            else
               me.sendServerError response

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

      sendServerError : (response) ->
         response.writeHead 500, {'Content-Type':'text/plain'}
         response.end()

      sendSaveError : (response) ->
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
