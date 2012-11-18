times = require '../prototype/times'

module.exports =
   spacing: (length = 0) ->
      ' '.times length

   wrap: (tokens, continuation = 0, columns = process.stdout.columns) ->
      if continuation + tokens.join(' ').length <= columns
         return tokens.join(' ')

      wrapped = ''
      gutter = @spacing continuation

      for token in tokens
         do (token) =>
            lengthSoFar = (continuation + (wrapped.replace(/\n/g,'').length) % columns) or columns
            if (lengthSoFar + token.length) > columns
               wrapped += "\n#{gutter}#{token}"
            else
               wrapped += " #{token}"

      return wrapped.trim()
