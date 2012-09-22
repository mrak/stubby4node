#!/usr/bin/env coffee

Admin = require('./portals/admin').Admin
Stub = require('./portals/stub').Stub
Endpoints = require('./models/endpoints').Endpoints
CLI = require('./cli')
http = require 'http'
https = require 'https'

onListening = (portal, port, protocol = 'http') ->
   CLI.dark "#{portal} portal running at #{protocol}://#{args.location}:#{port}"
onError = (err, port) ->
   switch err.code
      when 'EACCES'
         CLI.error "Permission denied for use of port #{port}. Exiting..."
         process.exit()
      when 'EADDRINUSE'
         CLI.error "Port #{port} is already in use! Exiting..."
         process.exit()
      when 'EADDRNOTAVAIL'
         CLI.error "Host \"#{args.location}\" is not available! Exiting..."
         process.exit()
      else
         CLI.error "#{err.message}. Exiting..."
         process.exit()

args = CLI.getArgs()
endpoints = new Endpoints(args.data)

stubServer = (new Stub(endpoints)).server
adminServer = (new Admin(endpoints)).server

options = false
protocol = 'http'
if args.key and args.cert
   options =
      key: args.key
      cert: args.cert
else if args.pfx
   options =
      pfx: args.pfx

if not options
   stubServer = http.createServer(stubServer)
else
   protocol = 'https'
   stubServer = https.createServer(options, stubServer)
stubServer.on 'listening', -> onListening 'Stub', args.stub, protocol
stubServer.on 'error', (err) -> onError(err, args.stub)
stubServer.listen args.stub, args.location, protocol

adminServer = http.createServer(adminServer)
adminServer.on 'listening', -> onListening 'Admin', args.admin
adminServer.on 'error', (err) -> onError(err, args.admin)
adminServer.listen args.admin, args.location

CLI.log '''

   Quit: ctrl-c

   Log:'''
