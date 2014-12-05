assert = require 'assert'
sut = null

describe 'args', ->
   beforeEach ->
      sut = require '../lib/console/args'

   describe 'parse', ->
      describe 'flags', ->
         it 'should parse a flag without parameters', ->
            options = [
               name: 'flag'
               flag: 'f'
            ]

            result = sut.parse options, ['-f']

            assert result.flag is true

         it 'should parse two flags without parameters', ->
            options = [
               name: 'one'
               flag: 'o'
            ,
               name: 'two'
               flag: 't'
            ]

            result = sut.parse options, ['-ot']

            assert result.one is true
            assert result.two is true

         it 'should default to false for flag without parameters', ->
            options = [
               name: 'flag'
               flag: 'f'
            ]

            result = sut.parse options, []

            assert result.flag is false


         it 'should parse a flag with parameters', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
            ]

            result = sut.parse options, ['-f', expected]

            assert result.flag is expected

         it 'should parse two flags with parameters', ->
            options = [
               name: 'one'
               flag: 'o'
               param: 'named'
            ,
               name: 'two'
               flag: 't'
               param: 'named'
            ]

            result = sut.parse options, ['-o', 'one', '-t', 'two']

            assert result.one is 'one'
            assert result.two is 'two'

         it 'should be default if flag not supplied', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, []

            assert result.flag is expected

         it 'should be default if flag parameter not supplied', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, ['-f']

            assert result.flag is expected

         it 'should be default if flag parameter skipped', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, ['-f', '-z']

            assert result.flag is expected

         it 'should parse a flag with parameters combined with a flag without parameters', ->
            options = [
               name: 'one'
               flag: 'o'
               param: 'named'
            ,
               name: 'two'
               flag: 't'
            ]

            result = sut.parse options, ['-ot', 'one']

            assert result.one is 'one'
            assert result.two is true

      describe 'names', ->
         it 'should parse a name without parameters', ->
            options = [
               name: 'flag'
               flag: 'f'
            ]

            result = sut.parse options, ['--flag']

            assert result.flag is true


         it 'should parse two names without parameters', ->
            options = [
               name: 'one'
               flag: 'o'
            ,
               name: 'two'
               flag: 't'
            ]

            result = sut.parse options, ['--one', '--two']

            assert result.one is true
            assert result.two is true

         it 'should default to false for name without parameters', ->
            options = [
               name: 'flag'
               flag: 'f'
            ]

            result = sut.parse options, []

            assert result.flag is false

         it 'should parse a name with parameters', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
            ]

            result = sut.parse options, ['--flag', expected]

            assert result.flag is expected

         it 'should parse two names with parameters', ->
            options = [
               name: 'one'
               flag: 'o'
               param: 'named'
            ,
               name: 'two'
               flag: 't'
               param: 'named'
            ]

            result = sut.parse options, ['--one', 'one', '--two', 'two']

            assert result.one is 'one'
            assert result.two is 'two'

         it 'should be default if name not supplied', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, []

            assert result.flag is expected

         it 'should be default if name parameter not supplied', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, ['--flag']

            assert result.flag is expected

         it 'should be default if name parameter skipped', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, ['--flag', '--another-flag']

            assert result.flag is expected

