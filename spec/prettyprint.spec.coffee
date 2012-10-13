sut = require '../src/console/prettyprint'

describe 'prettyprint', ->
   describe 'spacing', ->
      it 'should return an empty string if given no parameters', ->
         actual = sut.spacing()

         expect(actual).toBe ''

      it 'should return five spaces if given 5', ->
         actual = sut.spacing 5

         expect(actual).toBe '     '

      it 'should return empty string if given negative number', ->
         actual = sut.spacing -5

         expect(actual).toBe ''

   describe 'wrap', ->
      it 'should linebreak at word instead of character given tokens', ->
         continuationIndent = 0
         columns = 25
         words = "one fish, two fish, red fish, blue fish".split(' ')
         actual = sut.wrap(words, continuationIndent, columns)

         expect(actual).toBe 'one fish, two fish, red\nfish, blue fish'

      it 'should indent before subsequent lines', ->
         continuationIndent = 5
         columns = 25
         words = "one fish, two fish, red fish, blue fish".split(' ')
         actual = sut.wrap(words, continuationIndent, columns)

         expect(actual).toBe '''one fish, two fish,\n     red fish, blue fish'''

      it 'should wrap past multiple lines', ->
         continuationIndent = 5
         columns = 15
         words = "one fish, two fish, red fish, blue fish".split(' ')
         actual = sut.wrap(words, continuationIndent, columns)

         expect(actual).toBe '''one fish,\n     two fish,\n     red fish,\n     blue fish'''

