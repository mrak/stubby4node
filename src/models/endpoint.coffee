fs = require 'fs'
path = require 'path'

normalizeEOL = (string) ->
   return (string.replace /\r\n/g, '\n').replace /\s*$/, ''

purifyHeaders = ->
   for prop, value of @request.headers
      delete @request.headers[prop]
      @request.headers[prop.toLowerCase()] = value

   for prop, value of @response.headers
      delete @response.headers[prop]
      @response.headers[prop.toLowerCase()] = value

purifyAuthorization = ->
   return unless @request.headers?.authorization

   auth = @request.headers.authorization ? ''

   return unless auth.match /:/

   @request.headers.authorization = 'Basic ' + new Buffer(auth).toString 'base64'

purifyBody = ->
   @response.body ?= ''
   if typeof @response.body is 'object'
      @response.body = JSON.stringify @response.body

   @response.body = new Buffer(@response.body)

pruneUndefined = ->
   for key, value of @request
      delete @request[key] unless value?
   for key, value of @response
      delete @response[key] unless value?

setFallbacks = (endpoint) ->
   if endpoint.request.file?
      try endpoint.request.post = fs.readFileSync endpoint.request.file, 'utf8'

   if endpoint.response.file?
      try endpoint.response.body = fs.readFileSync endpoint.response.file, 'utf8'

compareHashMaps = (configured = {}, incoming = {}) ->
   for key, value of configured
      if configured[key] isnt incoming[key] then return false
   return true

module.exports = class Endpoint
   constructor: (endpoint = {}, datadir = process.cwd()) ->
      Object.defineProperty @, 'datadir', value: datadir

      endpoint.request ?= {}
      endpoint.response ?= {}

      @request =
         url: endpoint.request.url
         method: endpoint.request.method ? 'GET'
         headers: endpoint.request.headers
         query: endpoint.request.query
         file: endpoint.request.file
         post: endpoint.request.post
      @response =
         headers: endpoint.response.headers
         status: parseInt(endpoint.response.status) or 200
         latency: parseInt(endpoint.response.latency) or undefined
         file: endpoint.response.file
         body: endpoint.response.body

      purifyHeaders.call @
      purifyAuthorization.call @
      purifyBody.call @
      pruneUndefined.call @

   matches: (request) ->
      return false unless RegExp(@request.url).test request.url
      return false unless compareHashMaps @request.headers, request.headers
      return false unless compareHashMaps @request.query, request.query

      file = null
      if @request.file?
         try file = fs.readFileSync path.resolve(@datadir, @request.file), 'utf8'

      if post = file or @request.post
         return false unless normalizeEOL(post) is normalizeEOL(request.post)

      if @request.method instanceof Array
         return false unless request.method in @request.method.map (it) -> it.toUpperCase()
      else
         return false unless @request.method.toUpperCase() is request.method

      return true


