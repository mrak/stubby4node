fs = require 'fs'
module.exports.CLI = class CLI
   constructor : ->
      argv = process.argv
      @file = []
      @ports =
         #stub : 8882
         #admin : 8889
         stub : 80
         admin : 81

      fileOptionIndex = argv.indexOf('--file') + 1 or argv.indexOf('-f') + 1
      if fileOptionIndex
         filename = argv[fileOptionIndex]
         file = fs.readFileSync filename, 'utf8'
         extension = filename.replace /^.*\.([a-zA-Z0-9]+)$/, '$1'
         if file
            switch extension
               when 'json'
                  try
                     @file = JSON.parse file
                  catch e
                     console.error "Couldn't load #{filename} due to syntax errors:"
                     console.dir e
                     @file = []
               when 'yaml','yml'
                  yaml = require 'js-yaml'
                  @file = yaml.load file

      stubOptionIndex = argv.indexOf('--stub') + 1 or argv.indexOf('-s') + 1
      @ports.stub = parseInt(argv[stubOptionIndex]) ? @ports.stub if stubOptionIndex

      adminOptionIndex = argv.indexOf('--admin') + 1 or argv.indexOf('-a') + 1
      @ports.admin = parseInt(argv[adminOptionIndex]) ? @ports.admin if adminOptionIndex

   red: '\u001b[31m'
   yellow: '\u001b[33m'
   green: '\u001b[32m'
   blue: '\u001b[34m'
   reset: '\u001b[0m'

   info: (msg) ->
      console.log "#{@blue}#{msg}#{@reset}"
   success: (msg) ->
      console.log "#{@green}#{msg}#{@reset}"
   error: (msg) ->
      console.error "#{@red}#{msg}#{@reset}"
   warn: (msg) ->
      console.warn "#{@yellow}#{msg}#{@yellow}"
