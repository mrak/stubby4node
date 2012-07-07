option '-s', '--stub [PORT]', 'stub port'
option '-a', '--admin [PORT]', 'admin port'
option '-f', '--file [FILE]', 'data file'

{print} = require 'util'
{spawn} = require 'child_process'
fs = require 'fs'

task 'run', 'Run the stub and admin portals', (options) ->
   args = [
      'src/server.coffee'
      '-a'
      options.admin or 81
      '-s'
      options.stub or 80
   ]
   args.concat [ '-f', options.file] if options.file?

   coffee = spawn 'coffee', args

   coffee.stderr.on 'data', (data) ->
      process.stderr.write data.toString()
   coffee.stdout.on 'data', (data) ->
      print data.toString()
   coffee.on 'exit', (code) ->
      callback?() if code is 0

task 'singlefile', 'Generates stubby4node as a single .coffee file', ->
   singlefile = 'stubby4node.coffee'
   appContents = new Array
   files = [
      'cli'
      'models/contract'
      'models/endpoint'
      'portals/stub'
      'portals/admin'
      'server'
   ]
   remaining = files.length

   for file, index in files then do (file, index) ->
      fs.readFile "src/#{file}.coffee", 'utf8', (err, fileContents) ->
         throw err if err
         fileContents = fileContents.replace /#INCLUDES BEGIN(\n|.)*#INCLUDES END/, ''
         appContents[index] = fileContents
         process() if --remaining is 0

   process = ->
      fs.writeFile singlefile, appContents.join('\n\n'), 'utf8', (err) ->
         throw err if err
         console.log "Generated #{singlefile}"
