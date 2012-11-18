pp = require './prettyprint'

UNARY_FLAGS = /^-[a-zA-Z]+$/
ANY_FLAG = /^-.*$/

findOption = (option, argv) ->
   argIndex = -1
   if option.flag?
      argIndex = argv.indexOf("-#{option.flag}")

   if argIndex is -1 and option.name?
      argIndex = argv.indexOf("--#{option.name}")

   return argIndex

optionSkipped = (index, argv) ->
   argv[index + 1].match ANY_FLAG

unaryCheck = (option, argv) ->
   return true if option.name? and "--#{option.name}" in argv

   if option.flag?
      flags = (flag for flag in argv when flag.match UNARY_FLAGS)

      found = false

      for flag in flags
         do (flag) ->
            if option.flag in flag then found = true

      return found

   return false

pullPassedValue = (option, argv) ->
   return unaryCheck option, argv unless option.param?

   argIndex = findOption option, argv

   return option.default if argIndex is -1
   return option.default unless argv[argIndex + 1]?

   unless optionSkipped argIndex, argv
      return argv[argIndex + 1]

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
