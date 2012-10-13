String.prototype.times = (num = 1) ->
   return '' if num < 1

   result = ''
   for i in [1..num]
      result += @
   return result
