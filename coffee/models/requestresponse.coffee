RequestResponse = module.exports.RequestResponse = () ->
   methods = [
      'GET'
      'PUT'
      'POST'
      'HEAD'
      'TRACE'
      'DELETE'
      'CONNECT'
      'OPTIONS'
   ]
   me = {
      ObjectID: require('mongodb').ObjectID
      create : (data) ->
         data = data ? {}

         if data.method and data.method not in methods then return null
         if data.status and typeof(data.status) not 'number' then return null
         if not data.url then return null

         rnr =
            _id : new me.ObjectID()
            request :
               url : data.url
               method : data.method ? 'GET'
               post : data.post
            response :
               headers : data.headers ? {}
               status : data.status ? 200
               content : data.content
         return rnr
   }
