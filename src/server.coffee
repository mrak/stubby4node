Admin = require('./portals/admin').Admin
Stub = require('./portals/stub').Stub
Endpoint = require('./models/endpoint').Endpoint
CLI = require('./cli').CLI

http = require 'http'

args = CLI.getArgs()
endpoint = new Endpoint(args.file)

console.log ''

stubServer = (new Stub(endpoint)).server
http.createServer(stubServer).listen args.stub
CLI.info "Stub portal running at localhost:#{args.stub}"

adminServer  = (new Admin(endpoint)).server
http.createServer(adminServer).listen args.admin
CLI.info "Admin portal running at localhost:#{args.admin}"

console.log '\nREQUESTS:'
