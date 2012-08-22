fs = require 'fs'

module.exports =
   mute: false

   defaults:
      stub: 8882
      admin: 8889
      location: 'localhost'

   help: (argv, quit = false) ->
      argv ?= process.argv

      if '--help' in argv or '-h' in argv
         @log """
            stubby [-s <port>] [-a <port>] [-d <file>] [-l <hostname>]
                   [-h] [-v] [-k <file>] [-c <file>] [-p <file>]\n
            -s, --stub [PORT]                    Port that stub portal should
                                                 run on. Defaults to 8882.

            -a, --admin [PORT]                   Port that admin portal should
                                                 run on. Defaults to 8889.

            -d, --data [FILE.{json|yml|yaml}]    Data file to pre-load endoints.

            -l, --location [HOSTNAME]            Host at which to run stubby.

            -h, --help                           This help text.

            -v, --version                        Prints stubby's version number.

            -k, --key [FILE.pem]                 Private key file in PEM format
                                                 for https. Requires --cert

            -c, --cert [FILE.pem]                Certificate key file in PEM
                                                 format for https.
                                                 Requres --key.

            -p, --pfx [FILE.pfx]                 Key, certificate key and
                                                 trusted certificates in pfx
                                                 format. Mutually exclusive with
                                                 --key,--cert
         """
         process.exit 0 if quit

   version: (argv, quit = false) ->
      if '--version' in argv or '-v' in argv
         data = require '../package.json'
         @log data.version
         process.exit 0 if quit

   getAdmin: (argv) ->
      argv ?= process.argv
      admin = @defaults.admin

      adminOptionIndex = argv.indexOf('--admin') + 1 or argv.indexOf('-a') + 1
      admin = parseInt(argv[adminOptionIndex]) ? admin if adminOptionIndex

      return admin

   getLocation: (argv) ->
      argv ?= process.argv
      location = @defaults.location

      locationOptionIndex = argv.indexOf('--location') + 1 or argv.indexOf('-l') + 1
      location = argv[locationOptionIndex] ? locaiton if locationOptionIndex

      return location

   getStub: (argv) ->
      argv ?= process.argv
      stub = @defaults.stub

      stubOptionIndex = argv.indexOf('--stub') + 1 or argv.indexOf('-s') + 1
      stub = parseInt(argv[stubOptionIndex]) ? stub if stubOptionIndex

      return stub

   getData: (argv) ->
      argv ?= process.argv
      file = []

      fileOptionIndex = argv.indexOf('--data') + 1 or argv.indexOf('-d') + 1
      if fileOptionIndex
         filename = argv[fileOptionIndex]
         filedata = fs.readFileSync filename, 'utf8'
         extension = filename.replace /^.*\.([a-zA-Z0-9]+)$/, '$1'
         if filedata
            switch extension
               when 'json'
                  try
                     file = JSON.parse filedata
                  catch e
                     @error "Couldn't load #{filename} due to syntax errors:"
                     @dump e
                     file = []
               when 'yaml','yml'
                  try
                     yaml = require 'js-yaml'
                     file = yaml.load filedata
                  catch e
                     @warn "Module 'js-yaml' is required for parsing yaml data. No data loaded."

      return file

   getKey: (argv) ->
      @getFile argv, '-k', '--key', 'pem'

   getCert: (argv) ->
      @getFile argv, '-c', '--cert', 'pem'

   getPfx: (argv) ->
      @getFile argv, '-p', '--pfx', 'pfx'

   getFile: (argv, flag, option, type) ->
      argv ?= process.argv
      pem = null

      certOptionIndex = argv.indexOf(option) + 1 or argv.indexOf(flag) + 1
      if certOptionIndex
         filename = argv[certOptionIndex]
         filedata = fs.readFileSync filename, 'utf8'
         extension = filename.replace /^.*\.([a-zA-Z0-9]+)$/, '$1'
         if extension isnt type
            CLI.warn "[#{flag}, #{option}] only takes files of type .#{type}. Ignoring..."
            return null
         if filedata
            pem = filedata

      return pem?.trim() or null

   getArgs: (argv) ->
      argv ?= process.argv
      @help argv, true
      @version argv, true

      args =
         data: @getData argv
         stub: @getStub argv
         admin: @getAdmin argv
         location: @getLocation argv
         key: @getKey argv
         cert: @getCert argv
         pfx: @getPfx argv

   red: '\u001b[31m'
   green: '\u001b[32m'
   yellow: '\u001b[33m'
   blue: '\u001b[34m'
   purple: '\u001b[35m'
   reset: '\u001b[0m'

   log: (msg) ->
      if @mute then return
      console.log msg
   dump: (data) ->
      if @mute then return
      console.dir data
   info: (msg) ->
      if @mute then return
      console.info "#{@blue}#{msg}#{@reset}"
   success: (msg) ->
      if @mute then return
      console.log "#{@green}#{msg}#{@reset}"
   error: (msg) ->
      if @mute then return
      console.error "#{@red}#{msg}#{@reset}"
   warn: (msg) ->
      if @mute then return
      console.warn "#{@yellow}#{msg}#{@reset}"
   notice: (msg) ->
      if @mute then return
      console.log "#{@purple}#{msg}#{@reset}"
