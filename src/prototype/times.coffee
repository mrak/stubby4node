Object.defineProperty Number.prototype, "times",
   configurable: true
   value: (fn = ->) ->
      return @ unless @ > 0
      for i in [1..@]
         fn()
      return parseFloat @

Object.defineProperty String.prototype, "times",
   configurable: true
   value: (num = 1) ->
      result = ''
      if num < 1 then return result

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
