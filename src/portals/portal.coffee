CLI = require '../cli'
http = require 'http'

module.exports.Portal = class Portal
   constructor: ->
      @name = 'portal'

   received: (request) ->
      date = new Date()
      hours = "0#{date.getHours()}".slice -2
      minutes = "0#{date.getMinutes()}".slice -2
      seconds = "0#{date.getSeconds()}".slice -2
      CLI.incoming "#{hours}:#{minutes}:#{seconds} -> #{request.method} #{@name}#{request.url}"

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

      CLI[fn] "#{hours}:#{minutes}:#{seconds} <- #{status} #{@name}#{url} #{message}"

