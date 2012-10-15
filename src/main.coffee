Admin = require('./portals/admin').Admin
Stubs = require('./portals/stubs').Stubs
Endpoints = require('./models/endpoints').Endpoints
contract = require './models/contract'

CLI = require './console/cli'
(require './console/out').mute = true

http = require 'http'
https = require 'https'

if global.TESTING then http = global.TESTING.http
if global.TESTING then https = global.TESTING.https

module.exports.Stubby = class Stubby
   constructor: ->
      @endpoints = new Endpoints()
      @stubsPortal = null
      @adminPortal = null

   start: (options, callback) -> process.nextTick =>
      @stop()

      if typeof options is 'function'
         callback = options

      callback ?= ->
      options ?= {}
      options.stubs ?= CLI.defaults.stubs
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
         @stubsPortal = https.createServer httpsOptions, new Stubs(@endpoints).server
      else if options.pfx
         options =
            pfx: options.pfx
         @stubsPortal = https.createServer httpsOptions, new Stubs(@endpoints).server
      else
         @stubsPortal = http.createServer(new Stubs(@endpoints).server)

      @admimPortal = http.createServer(new Admin(@endpoints).server)

      @stubsPortal.listen options.stubs, options.location
      @admimPortal.listen options.admin, options.location

      callback()

   stop: =>
      if @stubsPortal?.address() then @stubsPortal.close()
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
         @endpoints.retrieve id, callback

   put: (id, data, callback) -> process.nextTick =>
      callback ?= ->
      if not contract data then return callback "The supplied endpoint data couldn't be saved"
      @endpoints.update id, data, callback

   delete: (id, callback) -> process.nextTick =>
      callback ?= ->
      if id?
         @endpoints.delete id, callback
      else
         delete @endpoints.db
         @endpoints.db = {}
         callback()
