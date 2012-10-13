Admin = require('./portals/admin').Admin
Stub = require('./portals/stub').Stub
Endpoints = require('./models/endpoints').Endpoints
CLI = require './console/cli'
out = require './console/out'
http = require 'http'
https = require 'https'

onListening = (portal, port, protocol = 'http') ->
   out.status "#{portal} portal running at #{protocol}://#{args.location}:#{port}"
onError = (err, port) ->
   msg = "#{err.message}. Exiting..."

   switch err.code
      when 'EACCES'
         msg = "Permission denied for use of port #{port}. Exiting..."
      when 'EADDRINUSE'
         msg = "Port #{port} is already in use! Exiting..."
      when 'EADDRNOTAVAIL'
         msg = "Host \"#{args.location}\" is not available! Exiting..."

   out.error msg
   process.exit()

args = CLI.getArgs()

onEndpointLoaded = (err, endpoint) -> out.notice "Loaded: #{endpoint.request.method} #{endpoint.request.url}"
endpoints = new Endpoints(args.data, onEndpointLoaded)

stubServer = (new Stub(endpoints)).server
adminServer = (new Admin(endpoints)).server

httpsOptions = false
protocol = 'http'
if args.key and args.cert
   httpsOptions =
      key: args.key
      cert: args.cert
else if args.pfx
   httpsOptions =
      pfx: args.pfx

unless httpsOptions
   stubServer = http.createServer(stubServer)
else
   protocol = 'https'
   stubServer = https.createServer(httpsOptions, stubServer)
stubServer.on 'listening', -> onListening 'Stub', args.stub, protocol
stubServer.on 'error', (err) -> onError(err, args.stub)
stubServer.listen args.stub, args.location, protocol

adminServer = http.createServer(adminServer)
adminServer.on 'listening', -> onListening 'Admin', args.admin
adminServer.on 'error', (err) -> onError(err, args.admin)
adminServer.listen args.admin, args.location

out.info '\nQuit: ctrl-c\n'
