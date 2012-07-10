#INCLUDES BEGIN
Admin = require('./portals/admin').Admin
Stub = require('./portals/stub').Stub
Endpoint = require('./models/endpoint').Endpoint
CLI = require('./cli').CLI
#INCLUDES END

http = require 'http'

cli = new CLI()
endpoint = new Endpoint(cli.file)

console.log ''

stubServer = (new Stub(endpoint)).server
http.createServer(stubServer).listen cli.ports.stub
cli.info "Stub portal running at localhost:#{cli.ports.stub}"

adminServer  = (new Admin(endpoint)).server
http.createServer(adminServer).listen cli.ports.admin
cli.info "Admin portal running at localhost:#{cli.ports.admin}"

console.log '\nREQUESTS:'
