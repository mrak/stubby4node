http = require 'http'
yaml = require 'js-yaml'
fs = require 'fs'
Admin = require('./portals/admin').Admin
Stub = require('./portals/stub').Stub
RnR = require('./models/requestresponse').RequestResponse
rNr = null
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
            rNr = new RnR JSON.parse file
         when 'yaml','yml'
            rNr = new RnR yaml.load file

rNr = rNr ? new RnR()

stubOptionIndex = process.argv.indexOf('--stub') + 1
stubport = parseInt(process.argv[stubOptionIndex]) ? stubport if stubOptionIndex

adminOptionIndex = process.argv.indexOf('--admin') + 1
adminport = parseInt(process.argv[adminOptionIndex]) ? adminport if adminOptionIndex

stubServer = (new Stub(rNr)).server
http.createServer(stubServer).listen stubport
console.log "Stub portal running at localhost:#{stubport}"

adminServer  = (new Admin(rNr)).server
http.createServer(adminServer).listen adminport
console.log "Admin portal running at localhost:#{adminport}"
