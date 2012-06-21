http = require 'http'
Admin = require('./portals/admin').Admin
Stub = require('./portals/stub').Stub
Endpoint = require('./models/endpoint').Endpoint
CLI = require('./cli').CLI

cli = new CLI process.argv
endpoint = new Endpoint(cli.file)

stubServer = (new Stub(endpoint)).server
http.createServer(stubServer).listen cli.ports.stub
console.log "Stub portal running at localhost:#{cli.ports.stub}"

adminServer  = (new Admin(endpoint)).server
http.createServer(adminServer).listen cli.ports.admin
console.log "Admin portal running at localhost:#{cli.ports.admin}"
