fs = require 'fs'
crypto = require 'crypto'
contract = require '../models/contract'
out = require './out'

timeout = 3000
timeoutId = null

module.exports = class Watcher =
   constructor: (endpoints, filename) ->
      @endpoints = endpoints
      @filename = filename

      shasum = crypto.createHash 'sha1'
      shasum.update fs.readFileSync @filename, 'utf8'
      @sha = shasum.digest 'hex'

      @activate()

   deactivate: -> clearTimeout timeoutId
   activate: -> timeoutId = setTimeout @refresh, timeout

   refresh: =>
      shasum = crypto.createHash 'sha1'
      data = fs.readFileSync @filename, 'utf8'

      shasum.update data
      sha = shasum.digest 'hex'

      if sha isnt @sha
         errors = contract data
         if errors
            out.error errors
         else
            endpoints.db = []
            endpoints.create data, (->)
            out.notice "Reloading #{filename}..."
            @sha = sha

      timeoutId = setTimeout @refresh, timeout

