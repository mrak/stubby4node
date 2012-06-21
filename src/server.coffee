http = require 'http'
yaml = require 'js-yaml'
fs = require 'fs'
Admin = require('./portals/admin').Admin
Stub = require('./portals/stub').Stub
Endpoint = require('./models/endpoint').Endpoint
endpoint = null
stubport = 80
adminport = 81

fileOptionIndex = process.argv.indexOf('--file') + 1
if fileOptionIndex
   filename = process.argv[fileOptionIndex]
   file = fs.readFileSync filename, 'utf8'
   extension = filename.replace /^.*\.([a-zA-Z0-9]+)$/, '$1'
   if file
      switch extension
         when 'json'
            endpoint = new Endpoint JSON.parse file
         when 'yaml','yml'
            endpoint = new Endpoint yaml.load file

endpoint = endpoint ? new Endpoint()

stubOptionIndex = process.argv.indexOf('--stub') + 1
stubport = parseInt(process.argv[stubOptionIndex]) ? stubport if stubOptionIndex

adminOptionIndex = process.argv.indexOf('--admin') + 1
adminport = parseInt(process.argv[adminOptionIndex]) ? adminport if adminOptionIndex

stubServer = (new Stub(endpoint)).server
http.createServer(stubServer).listen stubport
console.log "Stub portal running at localhost:#{stubport}"

adminServer  = (new Admin(endpoint)).server
http.createServer(adminServer).listen adminport
console.log "Admin portal running at localhost:#{adminport}"
