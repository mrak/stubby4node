Admin = require('./portals/admin').Admin
Stubs = require('./portals/stubs').Stubs
Endpoints = require('./models/endpoints').Endpoints
Watcher = require('./console/watch')
CLI = require './console/cli'
out = require './console/out'
http = require 'http'
https = require 'https'
contract = require './models/contract'

onListening = (portal, port, protocol = 'http', location) ->
   out.status "#{portal} portal running at #{protocol}://#{location}:#{port}"
onError = (err, port, location) ->
   msg = "#{err.message}. Exiting..."

   switch err.code
      when 'EACCES'
         msg = "Permission denied for use of port #{port}. Exiting..."
      when 'EADDRINUSE'
         msg = "Port #{port} is already in use! Exiting..."
      when 'EADDRNOTAVAIL'
         msg = "Host \"#{options.location}\" is not available! Exiting..."

   out.error msg
   console.dir err
   process.exit()

onEndpointLoaded = (err, endpoint) -> out.notice "Loaded: #{endpoint.request.method} #{endpoint.request.url}"

module.exports.Stubby = class Stubby
   constructor: ->
      @endpoints = new Endpoints()
      @stubsPortal = null
      @tlsPortal = null
      @adminPortal = null

   start: (options = {}, callback = ->) -> @stop =>
      if typeof options is 'function'
         callback = options
         options = {}

      options.mute ?= true

      defaults = CLI.getArgs []

      for key, value of defaults
         options[key] ?= value

      out.mute = options.mute

      if errors = contract options.data then return callback errors
      if options.datadir? then @endpoints.datadir = options.datadir
      @endpoints.create options.data, onEndpointLoaded

      httpsOptions = {}
      if options.key and options.cert
         httpsOptions =
            key: options.key
            cert: options.cert
      else if options.pfx
         httpsOptions =
            pfx: options.pfx

      @tlsPortal = https.createServer httpsOptions, new Stubs(@endpoints).server
      @tlsPortal.on 'listening', -> onListening 'Stubs', options.tls, 'https', options.location
      @tlsPortal.on 'error', (err) -> onError(err, options.tls, options.location)
      @tlsPortal.listen options.tls, options.location

      @stubsPortal = http.createServer(new Stubs(@endpoints).server)
      @stubsPortal.on 'listening', -> onListening 'Stubs', options.stubs, 'http', options.location
      @stubsPortal.on 'error', (err) -> onError(err, options.stubs, options.location)
      @stubsPortal.listen options.stubs, options.location

      @adminPortal = http.createServer(new Admin(@endpoints).server)
      @adminPortal.on 'listening', -> onListening 'Admin', options.admin, 'http', options.location
      @adminPortal.on 'error', (err) -> onError(err, options.admin, options.location)
      @adminPortal.listen options.admin, options.location

      if options.watch
         debugger
         @watcher = new Watcher @endpoints, options.watch

      out.info '\nQuit: ctrl-c\n'

      callback()

   stop: (callback = ->) => process.nextTick =>
      if @watcher? then @watcher.deactivate()

      if @adminPortal?.address()
         await @adminPortal.close defer()

      if @stubsPortal?.address()
         await @stubsPortal.close defer()

      if @tlsPortal?.address()
         await @tlsPortal.close defer()

      callback()


   post: (data, callback = ->) -> process.nextTick =>
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
