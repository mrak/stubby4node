fs = require 'fs'
yaml = require 'js-yaml'
pp = require './prettyprint'
out = require './out'

module.exports =
   options: [
      name: 'admin'
      param: 'port'
      flag: 'a'
      description: 'Port for admin portal. Defaults to 8889.'
   ,
      name: 'cert'
      param: 'file'
      flag: 'c'
      processed: true
      description: 'Certificate file. Use with --key.'
   ,
      name: 'data'
      flag: 'd'
      processed: true
      param: 'file'
      description: 'Data file to pre-load endoints. YAML or JSON format.'
   ,
      name: 'help'
      flag: 'h'
      exit: true
      description: 'This help text.'
   ,
      name: 'key'
      param: 'file'
      flag: 'k'
      processed: true
      description: 'Private key file. Use with --cert.'
   ,
      name: 'location'
      flag: 'l'
      param: 'hostname'
      description: 'Hostname at which to bind stubby.'
   ,
      name: 'mute'
      flag: 'm'
      processed: true
      description: 'Prevent stubby from printing to the console.'
   ,
      name: 'stub'
      param: 'port'
      flag: 's'
      description: 'Port for stub portal. Defaults to 8882.'
   ,
      name: 'pfx'
      flag: 'p'
      param: 'file'
      processed: true
      description: 'PFX file. Ignored if used with --key/--cert'
   ,
      name: 'version'
      flag: 'v'
      exit: true
      description: "Prints stubby's version number."
   ]

   defaults:
      stub: 8882
      admin: 8889
      location: 'localhost'
      data: null
      key: null
      cert: null
      pfx: null

   help: ->
      stubbyParams = []
      helpLines = []
      gutter = 28

      for option in @options
         do (option) =>
            param = if option.param? then " <#{option.param}>" else ''
            stubbyParams.push "[-#{option.flag}#{param}]"

            helpLine = "-#{option.flag}, --#{option.name}#{param}"
            helpLine += pp.spacing(gutter - helpLine.length)
            helpLine += pp.wrap option.description.split(' '), gutter
            helpLines.push helpLine

      "stubby #{pp.wrap stubbyParams, 7}\n\n#{helpLines.join '\n'}"


   version: -> (require '../../package.json').version
   mute: ->
      out.mute = true
   data: (filename) ->
      extension = filename.replace /^.*\.([a-zA-Z0-9]+)$/, '$1'
      filedata = []
      parser = ->

      try
         filedata = (fs.readFileSync filename, 'utf8').trim()
      catch e
         out.warn "File '#{filename}' could not be found. Ignoring..."
         return []

      if extension is 'json'
         parser = JSON.parse
      if extension in ['yaml','yml']
         parser = yaml.load

      try
         return parser filedata
      catch e
         out.warn "Couldn't parse '#{filename}' due to syntax errors:"
         out.log e.message
         process.exit 0

   key: (file) -> @readFile file, 'pem'
   cert: (file) -> @readFile file, 'pem'
   pfx: (file) -> @readFile file, 'pfx'

   readFile: (filename, type) ->
      filedata = fs.readFileSync filename, 'utf8'
      extension = filename.replace /^.*\.([a-zA-Z0-9]+)$/, '$1'

      return null unless filedata

      if extension isnt type
         out.warn "[#{flag}, #{option}] only takes files of type .#{type}. Ignoring..."
         return null

      return filedata.trim()

   getArgs: (argv = process.argv) ->
      args = {}

      for option in @options
         do (option) =>

            if @optionOmitted option, argv
               return args[option.name] = @defaults[option.name]

            @printAndExitIfNeeded option

            args[option.name] = @pullPassedValue option, argv

      return args

   pullPassedValue: (option, argv) ->
      argIndex = argv.indexOf("-#{option.flag}") + 1\
               or argv.indexOf("--#{option.name}") + 1
      arg = argv[argIndex] ? @defaults[option.name]
      if option.processed
         arg = @[option.name](arg)
      return arg

   optionOmitted: (option, argv) ->
      return "-#{option.flag}" not in argv\
             and "--#{option.name}" not in argv

   printAndExitIfNeeded: (option) ->
      if option.exit
         out.log @[option.name]()
         process.exit 0
