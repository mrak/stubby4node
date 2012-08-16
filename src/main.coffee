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

   start: (options, callback) ->
   stop: ->

   create: (data) ->
   read: (id) ->
   readAll: ->
   update: (id, data) ->
   destroy: (id) ->
   destroyAll: ->

