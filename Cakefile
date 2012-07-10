{exec} = require 'child_process'
fs = require 'fs'

task 'build', 'Generates stubby4node as a single .coffee file', ->
   singlefile = 'stubby4node'
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
      appContents.unshift "#!/usr/bin/env coffee"
      fs.writeFile singlefile, appContents.join('\n\n'), 'utf8', (err) ->
         throw err if err
         fs.chmodSync singlefile, '755'
         console.log "Generated #{singlefile}"

task 'convert', 'Converts stubby4j formatted yaml data to stubby4node formatted json data', ->
   fs.readFile 'data/data.yaml', 'utf8', (err, yaml) ->
      throw err if err
      yaml = yaml.replace /\n?httplifecycle:\n /g,'-'
      yaml = yaml.replace /\sbody:/g,' content:'
      fs.writeFile 'data/data4node.yaml', yaml, 'utf8', (err) ->
         throw err if err
         exec 'js-yaml -j data/data4node.yaml > data/data.json', ->
            fs.unlink 'data/data4node.yaml', (err) ->
               throw err if err
               console.log 'Conversion complete. Generated data/data.json'
