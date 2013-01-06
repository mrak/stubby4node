module.exports = Contract = (endpoint) ->
   httpMethods = [
      'GET'
      'PUT'
      'POST'
      'HEAD'
      'PATCH'
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
         query:
            type: "'request.query', if supplied, must be an object."
         method: "'request.method' must be one of #{httpMethods}."
         headers:
            type: "'request.headers', if supplied, must be an object."
            property: "'request.headers' must be strings or numbers."
      response:
         headers:
            type: "'response.headers', if supplied, must be an object."
            property: "'response.headers' must be strings or numbers."
         status:
            type: "'response.status' must be integer-like."
            small: "'response.status' must be >= 100."
            large: "'response.status' must be < 600."
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
         for key, value of headers
            if typeof value not in ['number', 'string']
               return messages.request.headers.property
         null
      method : (method) ->
         if not method then return null

         unless method instanceof Array
            return if method.toUpperCase() in httpMethods then null else messages.request.method

         for each in method
            do (each) ->
               unless each.toUpperCase() in httpMethods then return messages.request.method

         null

      query : (query) ->
         if not query then return null
         if query instanceof Array or typeof query isnt 'object'
            return messages.request.query.type
         null

   response =
      status : (status) ->
         if not status then return null
         parsed = parseInt status
         if not parsed then return messages.response.status.type
         if parsed < 100 then return messages.response.status.small
         if parsed >= 600 then return messages.response.status.large
         null
      headers : (headers) ->
         if not headers then return null
         if headers instanceof Array or typeof headers isnt 'object'
            return messages.response.headers.type
         for key, value of headers
            if typeof value not in ['number', 'string']
               return messages.response.headers.property
         null
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

   if endpoint.response
      for property of response
         errors.push response[property] endpoint.response[property]

   errors = errors.filter (error) -> error isnt null
   errors = null if errors.length is 0
   return errors
