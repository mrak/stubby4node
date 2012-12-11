http = require 'http'
qs = require 'querystring'

module.exports = (context) ->
   options =
      port: context.port
      method: context.method
      path: context.url
      headers: context.requestHeaders

   if context.query?
      options.path += "?#{qs.stringify context.query}"

   request = http.request options, (response) ->
      data = ''
      response.on 'data', (chunk) ->
         data += chunk
      response.on 'end', ->
         response.data = data
         context.response = response
         context.done = true

   request.write context.post if context.post?
   request.end()
   return request
