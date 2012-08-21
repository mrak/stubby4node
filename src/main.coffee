Admin = require('./portals/admin').Admin
Stub = require('./portals/stub').Stub
Endpoint = require('./models/endpoint').Endpoint
contract = require './models/contract'
CLI = require './cli'

http = require 'http'

endpoints = new Endpoint()
stub = http.createServer(new Stub(@endpoints).server)
admin = http.createServer(new Admin(@endpoints).server)

module.exports =
   start: (options, callback) ->
      if typeof options is 'function'
         callback = options
         options = {}
      options ?= {}
      options.stub ?= CLI.defaults.stub
      options.admin ?= CLI.defaults.admin
      options.location ?= CLI.defaults.location
      options.data ?= []
      CLI.mute = options.mute ? true

      endpoints.create options.data, ->

      stub.listen options.stub, options.location
      admin.listen options.admin, options.location

      callback() if callback?

   stop: ->
      stub.close()
      admin.close()

   mute: (mute) -> CLI.mute = mute ? true

   add: (data, callback) ->
      if not contract data then return callback "The supplied endpoint data couldn't be saved"
      fn = -> endpoints.create data, callback
      setTimeout fn, 1
   get: (id, callback) ->
      fn = null
      if typeof id is 'function'
         fn = -> endpoints.gather id, id
      else
         fn = -> endpoints.retrieve id, callback, callback
      setTimeout fn, 1
   set: (id, data, callback) ->
      if not contract data then return callback "The supplied endpoint data couldn't be saved"
      fn = -> endpoints.update id, data, callback, callback
      setTimeout fn, 1
   remove: (id, callback) ->
      if id?
         fn = -> endpoints.delete id, callback, -> callback true
         setTimeout fn, 1
      else
         delete endpoints.db
         endpoints.db = {}
