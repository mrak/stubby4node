pp = require './prettyprint'
out = require './out'

pullPassedValue = (option, argv) ->
   argIndex = -1
   if option.flag?
      argIndex = argv.indexOf("-#{option.flag}")

   if argIndex is -1 and option.name?
      argIndex = argv.indexOf("--#{option.name}")

   unless argIndex is -1
      return true if not option.param?
      return argv[argIndex + 1] ? option.default

   return option.default

module.exports =
   parse: (options, argv = process.argv) ->
      args = {}

      for option in options
         do (option) =>
            option.default ?= null
            args[option.name] = pullPassedValue option, argv

      return args

   helpText: (options, programName) ->
      stubbyParams = []
      helpLines = []
      gutter = 28

      for option in options
         do (option) =>
            param = if option.param? then " <#{option.param}>" else ''
            stubbyParams.push "[-#{option.flag}#{param}]"

            helpLine = "-#{option.flag}, --#{option.name}#{param}"
            helpLine += pp.spacing(gutter - helpLine.length)
            helpLine += pp.wrap option.description.split(' '), gutter
            helpLines.push helpLine

      return "#{programName} #{pp.wrap stubbyParams, 7}\n\n#{helpLines.join '\n'}"
