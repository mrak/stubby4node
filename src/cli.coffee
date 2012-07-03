fs = require 'fs'
#yaml = require 'js-yaml'

module.exports.CLI = class CLI
   constructor : (argv) ->
      @file = '[]'
      @ports =
         stub : 80
         admin : 81
      fileOptionIndex = argv.indexOf('--file') + 1
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
                  @file = yaml.load file

      stubOptionIndex = process.argv.indexOf('--stub') + 1
      @ports.stub = parseInt(process.argv[stubOptionIndex]) ? @ports.stub if stubOptionIndex

      adminOptionIndex = process.argv.indexOf('--admin') + 1
      @ports.admin = parseInt(process.argv[adminOptionIndex]) ? @ports.admin if adminOptionIndex
