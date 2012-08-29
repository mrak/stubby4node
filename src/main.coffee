Admin = require('./portals/admin').Admin
Stub = require('./portals/stub').Stub
Endpoints = require('./models/endpoints').Endpoints
contract = require './models/contract'

CLI = require './cli'
CLI.mute = true

http = require 'http'
https = require 'https'

if global.TESTING then http = global.TESTING.http
if global.TESTING then https = global.TESTING.https

module.exports.Stubby = class Stubby
   constructor: ->
      @endpoints = new Endpoints()
      @stubPortal = null
      @adminPortal = null

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
      options.key ?= null
      options.cert ?= null

      if not contract options.data then return callback "The supplied endpoint data couldn't be saved"
      @endpoints.create options.data, ->

      if options.key? and options.cert
         httpsOptions =
            key: options.key
            cert: options.cert
         @stubPortal = https.createServer httpsOptions, new Stub(@endpoints).server
      else if options.pfx
         options =
            pfx: options.pfx
         @stubPortal = https.createServer httpsOptions, new Stub(@endpoints).server
      else
         @stubPortal = http.createServer(new Stub(@endpoints).server)

      @admimPortal = http.createServer(new Admin(@endpoints).server)

      @stubPortal.listen options.stub, options.location
      @admimPortal.listen options.admin, options.location

      callback()

   stop: =>
      if @stubPortal?.address() then @stubPortal.close()
      if @admimPortal?.address() then @admimPortal.close()

   post: (data, callback) -> process.nextTick =>
      callback ?= ->
      if not contract data then return callback "The supplied endpoint data couldn't be saved"
      @endpoints.create data, callback

   get: (id, callback) -> process.nextTick =>
      callback ?= ->
      if typeof id is 'function'
         @endpoints.gather id, id
      else
         @endpoints.retrieve id, callback, callback

   put: (id, data, callback) -> process.nextTick =>
      callback ?= ->
      if not contract data then return callback "The supplied endpoint data couldn't be saved"
      @endpoints.update id, data, callback, callback

   delete: (id, callback) -> process.nextTick =>
      callback ?= ->
      if id?
         @endpoints.delete id, callback, -> callback true
      else
         delete @endpoints.db
         @endpoints.db = {}
         callback()
