pp = require './prettyprint'
out = require './out'

pullPassedValue = (option, argv) ->
   unless option.param? then return unaryCheck option, argv

   argIndex = -1
   if option.flag?
      argIndex = argv.indexOf("-#{option.flag}")

   if argIndex is -1 and option.name?
      argIndex = argv.indexOf("--#{option.name}")

   unless argIndex is -1
      return argv[argIndex + 1] ? option.default

   return option.default

unaryCheck = (option, argv) ->
   return true if option.name? and "--#{option.name}" in argv

   if option.flag?
      flags = (flag for flag in argv when flag.match /^\-[a-zA-Z]$/)

      found = false

      for flag in flags
         do (flag) ->
            if option.flag in flag then found = true

      return found

   return false

module.exports =
   parse: (options, argv = process.argv) ->
      args = {}

      for option in options
         do (option) =>
            option.default ?= null
            args[option.name] = pullPassedValue option, argv

      return args

   helpText: (options, programName) ->
      inlineList = []
      firstColumn = {}
      helpLines = []
      gutter = 3

      for option in options
         do (option) ->

            param = if option.param? then " <#{option.param}>" else ''
            firstColumn[option.name] = "-#{option.flag}, --#{option.name}#{param}"
            inlineList.push "[-#{option.flag}#{param}]"

            gutter = Math.max gutter, firstColumn[option.name].length + 3

      for option in options
         do (option) =>
            helpLine = firstColumn[option.name]
            helpLine += pp.spacing(gutter - helpLine.length)
            helpLine += pp.wrap option.description.split(' '), gutter
            helpLines.push helpLine

      return "#{programName} #{pp.wrap inlineList, programName.length + 1}\n\n#{helpLines.join '\n'}"
