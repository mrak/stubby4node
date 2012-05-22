mongo = require 'mongodb'
server = new mongo.Server 'localhost', 27017, {auto_reconnect : true}
ObjectID = mongo.ObjectID

Admin = module.exports.Admin = () ->
   db = new mongo.Db 'stubserver', server
   db.open () -> {}
   urlPattern = /^\/([a-f0-9]{24})?$/

   me = {
      qs: require 'querystring'

      db: db

      RnR: require('../models/requestresponse').RequestResponse()

      goPUT : (request, response) ->
         id = request.url.replace urlPattern, '$1'

         if id
            data = ''
            request.on 'data', (chunk) ->
               data += chunk

            request.on 'end', () ->
               data = me.qs.parse data
               rNr = me.RnR.create data

               if not rNr
                  me.send.saveError response
                  return

               rNr._id = new ObjectID id

               db.collection 'rnr', (err, collection) ->
                  if not err
                     collection.update {_id : new ObjectID id}, rNr, {safe:true}, (err, result) ->
                        if not err
                           if result
                              me.send.noContent response
                           else
                              me.send.notFound response
                        else
                           me.send.saveError response
                  else
                     me.send.serverError response
         else
            me.send.notFound response


      goPOST : (request, response) ->
         data = ''
         request.on 'data', (chunk) ->
            data += chunk

         request.on 'end', () ->
            data = me.qs.parse data
            rNr = me.RnR.create data

            if not rNr
               me.send.saveError response
               return

            db.collection 'rnr', (err, collection) ->
               if not err
                  collection.insert rNr, {safe:true}, (err, result) ->
                     if not err
                        me.send.created response, request, rNr._id
                     else
                        me.send.saveError response
               else
                  me.send.serverError response

      goDELETE : (request, response) ->
         id = me.getId request

         db.collection 'rnr', (err, collection) ->
            if not err
               collection.remove {_id : new ObjectID id}, {safe : true}, (err, result) ->
                  if not err
                     if not result
                        me.send.notFound response
                     else
                        me.send.noContent response
                  else
                     me.send.serverError response
            else
               me.send.serverError response

      goGET : (request, response) ->
         id = me.getId request

         if id
            db.collection 'rnr', (err, collection) ->
               if not err
                  collection.findOne {_id : new ObjectID id}, (err, result) ->
                     if not err
                        if not result
                           me.send.notFound response
                        else
                           me.send.ok response, result
                     else
                        me.send.serverError response
               else
                  me.send.serverError response
         else
            db.collection 'rnr', (err, collection) ->
               if not err
                  collection.find().toArray (err, result) ->
                     if not err
                        if result.length
                           me.send.ok response, result
                        else
                           me.send.noContent response
                     else
                        me.send.serverError response
               else
                  me.send.serverError response

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
            response.writeHead 405, {
               'Content-Type' : 'text/plain'
               'Allow' : 'GET, POST, PUT, DELETE, OPTIONS'
               'Content-Length' : 0
            }
            response.end()

         notFound : (response) ->
            response.writeHead 404, {'Content-Type' : 'text/plain'}
            response.end()

         serverError : (response) ->
            response.writeHead 500, {'Content-Type' : 'text/plain'}
            response.end()

         saveError : (response) ->
            response.writeHead 507, {'Content-Type' : 'text/plain'}
            response.end()

      urlValid : (url) ->
         return url.match urlPattern

      getId : (request) ->
         return request.url.replace urlPattern, '$1'

      server : (request, response) ->
         if me.urlValid request.url
            switch request.method.toUpperCase()
               when 'PUT'    then me.goPUT request, response
               when 'POST'   then me.goPOST request, response
               when 'DELETE' then me.goDELETE request, response
               when 'GET'    then me.goGET request, response
               else me.send.notSupported response
         else
            me.send.notFound response
   }
