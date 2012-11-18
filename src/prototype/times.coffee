Number.prototype.times = (fn) ->
   return @ unless @ > 0
   for i in [1..@]
      fn()
   return parseFloat @

String.prototype.times = (num = 1) ->
   return '' if num < 1

   result = ''
   for i in [1..num]
      result += @
   return result

module.exports = (left, right) ->
      return unless typeof left is 'number'

      if typeof right is 'function'
         return left.times right

      if typeof right is 'string'
         return right.times left

      return
