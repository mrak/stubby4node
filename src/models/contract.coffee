request =
   url : (url) ->
      if not url then return false
      true
   headers : (headers) ->
      if headers instanceof Array then return false
      if typeof headers isnt 'object' then return false
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
   body : -> true
   latency : -> true

exports.Contract = class Contract
   constructor : (endpoint) ->
      if typeof endpoint is 'string'
         try
            endpoint = JSON.parse endpoint
         catch e
            return false

      if not endpoint.request or not endpoint.response then return false

      for property of request
         if not request[property] endpoint.request[property] then return false
      for property of response
         if not response[property] endpoint.response[property] then return false

      return true
