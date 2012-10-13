stripper = (args) ->
   for key, value of args
      args[key] = value.replace /\u001b\[(\d+;?)+m/g, ''
   return args


module.exports = (console) ->
   if process.stdout.isTTY then return true

   console.raw = {}

   for fn in ['log', 'warn', 'info', 'error']
      do (fn) ->
         console.raw[fn] = console[fn]
         console[fn] = -> console.raw[fn].apply null, stripper(arguments)

   return false
