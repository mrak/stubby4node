assert = require 'assert'

module.exports = waitsFor = (fn, message, range, finish, time = process.hrtime()) ->
   min = range[0] ? 0
   max = range[1] ? range

   [seconds, nanoseconds] = process.hrtime(time)
   elapsed = seconds * 1000 + nanoseconds / 1000000

   assert elapsed < max, "Timed out waiting #{max}ms for #{message}"
   if fn()
      assert elapsed > min, "Condition succeeded before #{min}ms were up"
      return finish()

   setImmediate -> waitsFor.call @, fn, message, range, finish, time
