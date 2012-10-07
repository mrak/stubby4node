fs = require 'fs'
yaml = require 'js-yaml'
require('./colorsafe')(console)

module.exports =
   mute: false

   options: [{
      name: 'version'
      flag: 'v'
      exit: true
   },{
      name: 'help'
      flag: 'h'
      exit: true
   },{
      name: 'location'
      flag: 'l'
   },{
      name: 'data'
      flag: 'd'
      processed: true
   },{
      name: 'stub'
      flag: 's'
   },{
      name: 'admin'
      flag: 'a'
   },{
      name: 'key'
      flag: 'k'
      processed: true
   },{
      name: 'cert'
      flag: 'c'
      processed: true
   },{
      name: 'pfx'
      flag: 'p'
      processed: true
   }]

   defaults:
      stub: 8882
      admin: 8889
      location: 'localhost'
      data: null
      key: null
      cert: null
      pfx: null

   help: ->
         """
            stubby [-s <port>] [-a <port>] [-d <file>] [-l <hostname>]
                   [-h] [-v] [-k <file>] [-c <file>] [-p <file>]\n
            -s, --stub [PORT]                    Port for stub portal (8882)
            -a, --admin [PORT]                   Port for admin portal (8889)
            -d, --data [FILE.{json|yml|yaml}]    Data file to pre-load endoints.
            -l, --location [HOSTNAME]            Host at which to run stubby.
            -h, --help                           This help text.
            -v, --version                        Prints stubby's version number.
            -k, --key [FILE.pem]                 Private key file. With --cert.
            -c, --cert [FILE.pem]                Certificate key. With --key.
            -p, --pfx [FILE.pfx]                 Key, certificate key and
                                                 trusted certificates in pfx
                                                 format. Mutually exclusive with
                                                 --key,--cert
         """

   version: -> (require '../package.json').version
   location: (passed) -> return passed
   stub: (passed) -> return passed
   admin: (passed) -> return passed
   data: (filename) ->
      extension = filename.replace /^.*\.([a-zA-Z0-9]+)$/, '$1'
      filedata = []
      parser = ->

      try
         filedata = (fs.readFileSync filename, 'utf8').trim()
      catch e
         @warn "File '#{filename}' could not be found. Ignoring..."
         return []

      if extension is 'json'
         parser = JSON.parse
      if extension in ['yaml','yml']
         parser = yaml.load

      try
         return parser filedata
      catch e
         @warn "Couldn't parse '#{filename}' due to syntax errors: Ignoring..."
         return []

   key: (file) -> @getFile file, 'pem'

   cert: (file) -> @getFile file, 'pem'

   pfx: (file) -> @getFile file, 'pfx'

   getFile: (filename, type) ->
      filedata = fs.readFileSync filename, 'utf8'
      extension = filename.replace /^.*\.([a-zA-Z0-9]+)$/, '$1'

      return null unless filedata

      if extension isnt type
         CLI.warn "[#{flag}, #{option}] only takes files of type .#{type}. Ignoring..."
         return null

      return filedata.trim()

   getArgs: (argv = process.argv) ->
      args = {}

      for option in @options
         do (option) =>
            if "-#{option.flag}" not in argv\
            and "--#{option.name}" not in argv
               if @defaults[option.name]?
                  args[option.name] = @defaults[option.name]
               return

            if option.exit
               @log @[option.name]()
               process.exit 0

            argIndex = argv.indexOf("-#{option.flag}") + 1\
                     or argv.indexOf("--#{option.name}") + 1
            arg = argv[argIndex] ? @defaults[option.name]

            if option.processed
               arg = @[option.name](arg)

            args[option.name] = arg

      return args

   bold: '\x1B[1m'
   black: '\x1B[30m'
   blue: '\x1B[34m'
   cyan: '\x1B[36m'
   green: '\x1B[32m'
   purple: '\x1B[35m'
   red: '\x1B[31m'
   yellow: '\x1B[33m'
   reset: '\x1B[0m'

   log: (msg) ->
      if @mute then return
      console.log msg
   status: (msg) ->
      if @mute then return
      console.log "#{@bold}#{@black}#{msg}#{@reset}"
   dump: (data) ->
      if @mute then return
      console.dir data
   info: (msg) ->
      if @mute then return
      console.info "#{@blue}#{msg}#{@reset}"
   ok: (msg) ->
      if @mute then return
      console.log "#{@green}#{msg}#{@reset}"
   error: (msg) ->
      if @mute then return
      console.error "#{@red}#{msg}#{@reset}"
   warn: (msg) ->
      if @mute then return
      console.warn "#{@yellow}#{msg}#{@reset}"
   incoming: (msg) ->
      if @mute then return
      console.log "#{@cyan}#{msg}#{@reset}"
   notice: (msg) ->
      if @mute then return
      console.log "#{@purple}#{msg}#{@reset}"
   trace: ->
      if @mute then return
      console.log @red
      console.trace()
      console.log @reset
