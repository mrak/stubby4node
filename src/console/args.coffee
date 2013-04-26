pp = require './prettyprint'

UNARY_FLAGS = /^-[a-zA-Z]+$/
ANY_FLAG = /^-.+$/

findOption = (option, argv) ->
   argIndex = -1
   if option.flag?
      argIndex = indexOfFlag option, argv

   if argIndex is -1 and option.name?
      argIndex = argv.indexOf("--#{option.name}")

   return argIndex

indexOfFlag = (option, argv) ->
   flags = (flag for flag in argv when flag.match UNARY_FLAGS)
   index = -1

   for flag in flags
      do (flag) ->
         if option.flag in flag
            index = argv.indexOf(flag)

   return index


optionSkipped = (index, argv) ->
   argv[index + 1].match ANY_FLAG

unaryCheck = (option, argv) ->
   return true if option.name? and "--#{option.name}" in argv
   return false unless option.flag?

   return indexOfFlag(option, argv) isnt -1

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
            args[option.name ? options.flag] = pullPassedValue option, argv

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
