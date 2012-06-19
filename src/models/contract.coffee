module.exports.Contract = class Contract
   constructor : (endpoint) ->
      if typeof endpoint is 'string'
         try
            endpoint = JSON.parse endpoint
         catch e
            return false

      if not endpoint.request or not endpoint.response then return false

      return @request.url endpoint.url and
             @request.method endpoint.method and
             @request.post endpoint.post and
             @response.status endpoint.status and
             @response.headers endpoint.headers and
             @response.content endpoint.content


   request :
      url : (url) ->
         if not url then return false
         true
      method : (method) ->
         return method in [
            'GET'
            'PUT'
            'POST'
            'HEAD'
            'TRACE'
            'DELETE'
            'CONNECT'
            'OPTIONS'
         ]
      post : (post) -> true

   response :
      status : (status) ->
         if status and not parseInt status then return false
         true
      headers : (headers) ->
         if headers instanceof Array then return false
         if typeof headers isnt 'object' then return false
         true
      content : -> true
