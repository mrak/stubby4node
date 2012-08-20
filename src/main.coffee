Admin = require('./portals/admin').Admin
Stub = require('./portals/stub').Stub
CLI = require('./cli').CLI
Endpoint = require('./models/endpoint').Endpoint
Contract = require('./models/contract').Contract

http = require 'http'

exports.Stubby = class Stubby
   constructor: ->
      @endpoints = new Endpoint()
      @stub = http.createServer(new Stub(@endpoints).server)
      @admin = http.createServer(new Admin(@endpoints).server)
      CLI.mute = true

   start: (options, callback) ->
      options ?= {}
      options.stub ?= CLI.defaults.stub
      options.admin ?= CLI.defaults.admin
      options.location ?= CLI.defaults.location
      options.data ?= []

      @endpoints.create options.data, ->

      @stub.listen options.stub, options.location
      @admin.listen options.admin, options.location

   stop: ->
      @stub.close()
      @admin.close()

   mute: (mute) -> CLI.mute = mute ? true

   create: (data) ->
   read: (id, callback) ->
      fn = => @endpoints.retrieve id, callback, callback
      setTimeout fn, 1
   readAll: ->
      fn = => @endpoints.gather callback, callback
      setTimeout fn, 1
   update: (id, data) ->
   destroy: (id, callback) ->
      fn = => @endpoints.delete id, callback, -> callback true
      setTimeout fn, 1
   destroyAll: ->
      delete @endpoints.db
      @endpoints.db = {}

