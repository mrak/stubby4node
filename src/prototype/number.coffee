Number.prototype.times = (fn) -> 
   return @ unless @ > 0
   for i in [1..@]
      fn()
   return @
