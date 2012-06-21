request =
   url : (url) ->
      if not url then return false
      true
   method : (method) ->
      if not method then return true
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

response =
   status : (status) ->
      if not status then return true
      if not parseInt status then return false
      true
   headers : (headers) ->
      if headers instanceof Array then return false
      if typeof headers isnt 'object' then return false
      true
   content : -> true

module.exports.Contract = class Contract
   constructor : (endpoint) ->
      if typeof endpoint is 'string'
         try
            endpoint = JSON.parse endpoint
         catch e
            return false

      if not endpoint.request or not endpoint.response then return false

      return request.url(endpoint.request.url) and
             request.method(endpoint.request.method) and
             request.post(endpoint.request.post) and
             response.status(endpoint.response.status) and
             response.headers(endpoint.response.headers) and
             response.content(endpoint.response.content)

