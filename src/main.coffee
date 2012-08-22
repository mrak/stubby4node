Admin = require('./portals/admin').Admin
Stub = require('./portals/stub').Stub
Endpoint = require('./models/endpoint').Endpoint
contract = require './models/contract'
CLI = require './cli'

http = require 'http'

CLI.mute = true
endpoints = new Endpoint()
stub = http.createServer(new Stub(endpoints).server)
admin = http.createServer(new Admin(endpoints).server)

module.exports =
   start: (options, callback) -> process.nextTick =>
      @stop()

      if typeof options is 'function'
         callback = options

      callback ?= ->
      options ?= {}
      options.stub ?= CLI.defaults.stub
      options.admin ?= CLI.defaults.admin
      options.location ?= CLI.defaults.location
      options.data ?= []

      if not contract options.data then return callback "The supplied endpoint data couldn't be saved"
      endpoints.create options.data, ->

      stub.listen options.stub, options.location
      admin.listen options.admin, options.location

      callback()

   stop: ->
      if stub.address() then stub.close()
      if admin.address() then admin.close()

   mute: (mute) -> CLI.mute = mute ? true

   add: (data, callback) -> process.nextTick ->
      callback ?= ->
      if not contract data then return callback "The supplied endpoint data couldn't be saved"
      endpoints.create data, callback

   get: (id, callback) -> process.nextTick ->
      callback ?= ->
      if typeof id is 'function'
         endpoints.gather id, id
      else
         endpoints.retrieve id, callback, callback

   set: (id, data, callback) -> process.nextTick ->
      callback ?= ->
      if not contract data then return callback "The supplied endpoint data couldn't be saved"
      endpoints.update id, data, callback, callback

   remove: (id, callback) -> process.nextTick ->
      callback ?= ->
      if id?
         endpoints.delete id, callback, -> callback true
      else
         delete endpoints.db
         endpoints.db = {}
         callback()
