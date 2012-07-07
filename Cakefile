option '-s', '--stub [PORT]', 'stub port'
option '-a', '--admin [PORT]', 'admin port'
option '-f', '--file [FILE]', 'data file'

{print} = require 'util'
{spawn} = require 'child_process'

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
   console.log 'hello'
