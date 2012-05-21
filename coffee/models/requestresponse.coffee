RequestResponse = module.exports.RequestResponse = () ->
   me = {
      ObjectID: require('mongodb').ObjectID
      create : (data) ->
         data = data ? {}
         rnr =
            _id : new me.ObjectID()
            request :
               url : data.url
               method : data.method
               post : data.post
            response :
               headers : data.headers
               status : data.status
               content : data.content
         return rnr
   }
