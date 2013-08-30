CLI = require '../console/cli'
out = require '../console/out'
http = require 'http'

module.exports.Portal = class Portal
   constructor: ->
      @name = 'portal'

   writeHead: (response, status_code, headers) ->
      response.writeHead status_code, headers if !response.headersSent
      return response

   received: (request, response) ->
      date = new Date()
      hours = "0#{date.getHours()}".slice -2
      minutes = "0#{date.getMinutes()}".slice -2
      seconds = "0#{date.getSeconds()}".slice -2

      out.incoming "#{hours}:#{minutes}:#{seconds} -> #{request.method} #{@name}#{request.url}"
      response.setHeader 'Server', "stubby/#{CLI.version()} node/#{process.version} (#{process.platform} #{process.arch})"

   responded: (status, url = '', message = http.STATUS_CODES[status]) ->
      date = new Date()
      hours = "0#{date.getHours()}".slice -2
      minutes = "0#{date.getMinutes()}".slice -2
      seconds = "0#{date.getSeconds()}".slice -2

      fn = 'log'
      switch
         when 600 > status >= 400
            fn = 'error'
         when status >= 300
            fn = 'warn'
         when status >= 200
            fn = 'ok'
         when status >= 100
            fn = 'info'

      out[fn] "#{hours}:#{minutes}:#{seconds} <- #{status} #{@name}#{url} #{message}"

