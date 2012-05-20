ObjectID = require('mongodb').ObjectID

Request = module.exports.Request = (request) ->
   request = request ? {}
   return {
      _id : new ObjectID()
      method : request.method
      url : request.url
      'accept-language' : request['accept-language']
      'content-type' : request['content-type']
   }
