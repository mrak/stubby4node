fs = require 'fs'
yaml = require 'js-yaml'
out = require './out'
args = require './args'

module.exports =
   options: [
      name: 'admin'
      flag: 'a'
      param: 'port'
      default: 8889
      description: 'Port for admin portal. Defaults to 8889.'
   ,
      name: 'cert'
      flag: 'c'
      param: 'file'
      default: "#{__dirname}/../../tls/cert.pem"
      description: 'Certificate file. Use with --key.'
   ,
      name: 'data'
      flag: 'd'
      param: 'file'
      description: 'Data file to pre-load endoints. YAML or JSON format.'
   ,
      name: 'help'
      flag: 'h'
      exit: true
      default: false
      description: 'This help text.'
   ,
      name: 'key'
      flag: 'k'
      param: 'file'
      default: "#{__dirname}/../../tls/key.pem"
      description: 'Private key file. Use with --cert.'
   ,
      name: 'location'
      flag: 'l'
      param: 'hostname'
      default: 'localhost'
      description: 'Hostname at which to bind stubby.'
   ,
      name: 'mute'
      flag: 'm'
      description: 'Prevent stubby from printing to the console.'
   ,
      name: 'pfx'
      flag: 'p'
      param: 'file'
      description: 'PFX file. Ignored if used with --key/--cert'
   ,
      name: 'stubs'
      flag: 's'
      param: 'port'
      default: 8882
      description: 'Port for stubs portal. Defaults to 8882.'
   ,
      name: 'tls'
      flag: 't'
      param: 'port'
      default: 7443
      description: 'Port for https stubs portal. Defaults to 7443.'
   ,
      name: 'version'
      flag: 'v'
      exit: true
      description: "Prints stubby's version number."
   ,
      name: 'watch'
      flag: 'w'
      description: "Auto-reload data file when edits are made."
   ]

   help: (go = false) ->
      return unless go

      out.log args.helpText @options, 'stubby'

      process.exit()


   version: (go = false)->
      return unless go

      out.log (require '../../package.json').version
      process.exit()

   data: (filename) ->
      return [] if filename is null

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
      return null if filename is null

      filedata = fs.readFileSync filename, 'utf8'
      extension = filename.replace /^.*\.([a-zA-Z0-9]+)$/, '$1'

      return null unless filedata

      if extension isnt type
         out.warn "[#{flag}, #{option}] only takes files of type .#{type}. Ignoring..."
         return null

      return filedata.trim()

   getArgs: (argv = process.argv) ->
      params = args.parse @options, argv
      params.watch = params.data

      for option in @options
         do (option) =>
            if @[option.name]?
               params[option.name] = @[option.name] params[option.name]

      return params
