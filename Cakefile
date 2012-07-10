{exec} = require 'child_process'
fs = require 'fs'

task 'build', 'Generates stubby4node as a single executeable file', ->
   singlefile = 'stubby4node'
   appSrc = new Array
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
      fs.readFile "src/#{file}.coffee", 'utf8', (err, src) ->
         throw err if err
         appSrc[index] = src
         process() if --remaining is 0

   process = ->
      appSrc.unshift "#!/usr/bin/env coffee"
      appSrc = appSrc.join('\n')
      appSrc = appSrc.replace /^.*require\('\..*'\).*$/gm, ''
      appSrc = appSrc.replace /\n+/g, '\n'
      fs.writeFile singlefile, appSrc, 'utf8', (err) ->
         throw err if err
         fs.chmodSync singlefile, '755'
         console.log "Generated #{singlefile}"

task 'convert', 'Converts stubby4j formatted yaml data to stubby4node formatted json data', ->
   fs.readFile 'data/data.yaml', 'utf8', (err, yaml) ->
      throw err if err

      # random trailing whitespace. deadly in YAML
      yaml = yaml.replace /[ ]+$/gm, ''
      # you can't have values begin with * (unless it's a reference node)
      yaml = yaml.replace /: \*$/gm, ': "*"'
      # replace httplifecycle: with YAML sequence character '-'
      yaml = yaml.replace /\n?httplifecycle:\n\s/g,'-'
      # stubby4j uses 'body' stubby4node uses 'content'
      yaml = yaml.replace /\sbody:/g,' content:'

      fs.writeFile 'data/data4node.yaml', yaml, 'utf8', (err) ->
         throw err if err
         exec 'js-yaml -j data/data4node.yaml > data/data.json', ->
            fs.unlink 'data/data4node.yaml', (err) ->
               throw err if err
               console.log 'Conversion complete. Generated data/data.json'
