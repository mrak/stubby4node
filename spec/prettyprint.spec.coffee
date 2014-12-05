sut = require '../lib/console/prettyprint'
assert = require 'assert'

describe 'prettyprint', ->
   describe 'spacing', ->
      it 'should return an empty string if given no parameters', ->
         actual = sut.spacing()

         assert actual is ''

      it 'should return five spaces if given 5', ->
         actual = sut.spacing 5

         assert actual is '     '

      it 'should return empty string if given negative number', ->
         actual = sut.spacing -5

         assert actual is ''

   describe 'wrap', ->
      it 'should linebreak at word instead of character given tokens', ->
         continuationIndent = 0
         columns = 25
         words = "one fish, two fish, red fish, blue fish".split(' ')
         actual = sut.wrap(words, continuationIndent, columns)

         assert actual is 'one fish, two fish, red\nfish, blue fish'

      it 'should indent before subsequent lines', ->
         continuationIndent = 5
         columns = 25
         words = "one fish, two fish, red fish, blue fish".split(' ')
         actual = sut.wrap(words, continuationIndent, columns)

         assert actual is '''one fish, two fish,\n     red fish, blue fish'''

      it 'should wrap past multiple lines', ->
         continuationIndent = 5
         columns = 15
         words = "one fish, two fish, red fish, blue fish".split(' ')
         actual = sut.wrap(words, continuationIndent, columns)

         assert actual is '''one fish,\n     two fish,\n     red fish,\n     blue fish'''

