module.exports = Contract = (endpoint) ->
   httpMethods = [
      'GET'
      'PUT'
      'POST'
      'HEAD'
      'TRACE'
      'DELETE'
      'CONNECT'
      'OPTIONS'
   ]
   messages =
      json: "An unparseable JSON string was supplied."
      request:
         missing: "'request' object is required."
         url: "'request.url' is required."
         method: "'request.method' must be one of #{httpMethods}."
         headers:
            type: "'request.headers', if supplied, must be an object."
      response:
         missing: "'response' object is required."
         headers:
            type: "'response.headers', if supplied, must be an object."
         status:
            type: "'response.status' must be integer-like."
         latency:
            type: "'response.latency' must be integer-like."

   request =
      url : (url) ->
         if not url then return messages.request.url
         null
      headers : (headers) ->
         if not headers then return null
         if headers instanceof Array or typeof headers isnt 'object'
            return messages.request.headers.type
         null
      method : (method) ->
         if not method then return null
         return if method in httpMethods then null else messages.request.method
      post : (post) -> null

   response =
      status : (status) ->
         if not status then return null
         if not parseInt status then return messages.response.status.type
         null
      headers : (headers) ->
         if not headers then return null
         if headers instanceof Array or typeof headers isnt 'object'
            return messages.response.headers.type
         null
      body : -> null
      latency : (latency) ->
         if not latency then return null
         if not parseInt latency then return messages.response.latency.type
         null

   if typeof endpoint is 'string'
      try
         endpoint = JSON.parse endpoint
      catch e
         return [messages.json]

   if endpoint instanceof Array
      results = (Contract(each) for each in endpoint)

      results = results.filter (result) -> result isnt null
      return null if results.length is 0
      return results

   errors = []
   unless endpoint.request
      errors.push messages.request.missing
   else
      for property of request
         errors.push request[property] endpoint.request[property]
   unless endpoint.response
      errors.push messages.response.missing
   else
      for property of response
         errors.push response[property] endpoint.response[property]

   errors = errors.filter (error) -> error isnt null
   errors = null if errors.length is 0
   return errors
