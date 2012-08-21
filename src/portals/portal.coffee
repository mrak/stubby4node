module.exports.Portal = class Portal
   constructor: ->
      @name = 'portal'

   getLogLine: (request) ->
      date = new Date()
      hours = "0#{date.getHours()}".slice -2
      minutes = "0#{date.getMinutes()}".slice -2
      seconds = "0#{date.getSeconds()}".slice -2
      msg = "#{hours}:#{minutes}:#{seconds} -> #{request.method} #{@name}#{request.url}"
