mongo = require 'mongodb'
server = new mongo.Server 'localhost', 27017, {auto_reconnect : true}
ObjectID = mongo.ObjectID

Stub = module.exports.Stub = () ->
   db = new mongo.Db 'stubserver', server
   db.open () -> {}

   me = {
      server : (request, response) ->
         post = null
         request.on 'data', (chunk) ->
            post = post ? ''
            post += chunk

         request.on 'end', () ->
            post = me.qs.parse post if post?
            db.collection 'rnr', (err, collection) ->
               if not err
                  collection.findOne {'request.url' : request.url, 'request.method' : request.method, 'request.post' : post}, (err, result) ->
                     if not err
                        if result
                           headers = result.response.headers
                           response.writeHead result.response.status, headers
                           if result.response.content? then response.write result.response.content
                           response.end()
                        else
                           me.send.notFound response
                     else
                        me.send.serverError response
               else
                  me.send.serverError response
   }
