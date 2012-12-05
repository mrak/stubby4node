sut = null

describe 'args', ->
   beforeEach ->
      sut = require '../src/console/args'

   describe 'parse', ->
      describe 'flags', ->
         it 'should parse a flag without parameters', ->
            options = [
               name: 'flag'
               flag: 'f'
            ]

            result = sut.parse options, ['-f']

            expect(result.flag).toBe true

         it 'should parse two flags without parameters', ->
            options = [
               name: 'one'
               flag: 'o'
            ,
               name: 'two'
               flag: 't'
            ]

            result = sut.parse options, ['-ot']

            expect(result.one).toBe true
            expect(result.two).toBe true

         it 'should default to false for flag without parameters', ->
            options = [
               name: 'flag'
               flag: 'f'
            ]

            result = sut.parse options, []

            expect(result.flag).toBe false


         it 'should parse a flag with parameters', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
            ]

            result = sut.parse options, ['-f', expected]

            expect(result.flag).toBe expected

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

            expect(result.one).toBe 'one'
            expect(result.two).toBe 'two'

         it 'should be default if flag not supplied', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, []

            expect(result.flag).toBe expected

         it 'should be default if flag parameter not supplied', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, ['-f']

            expect(result.flag).toBe expected

         it 'should be default if flag parameter skipped', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, ['-f', '-z']

            expect(result.flag).toBe expected

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

            expect(result.one).toBe 'one'
            expect(result.two).toBe true

      describe 'names', ->
         it 'should parse a name without parameters', ->
            options = [
               name: 'flag'
               flag: 'f'
            ]

            result = sut.parse options, ['--flag']

            expect(result.flag).toBe true


         it 'should parse two names without parameters', ->
            options = [
               name: 'one'
               flag: 'o'
            ,
               name: 'two'
               flag: 't'
            ]

            result = sut.parse options, ['--one', '--two']

            expect(result.one).toBe true
            expect(result.two).toBe true

         it 'should default to false for name without parameters', ->
            options = [
               name: 'flag'
               flag: 'f'
            ]

            result = sut.parse options, []

            expect(result.flag).toBe false

         it 'should parse a name with parameters', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
            ]

            result = sut.parse options, ['--flag', expected]

            expect(result.flag).toBe expected

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

            expect(result.one).toBe 'one'
            expect(result.two).toBe 'two'

         it 'should be default if name not supplied', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, []

            expect(result.flag).toBe expected

         it 'should be default if name parameter not supplied', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, ['--flag']

            expect(result.flag).toBe expected

         it 'should be default if name parameter skipped', ->
            expected = 'a_value'
            options = [
               name: 'flag'
               flag: 'f'
               param: 'anything'
               default: expected
            ]

            result = sut.parse options, ['--flag', '--another-flag']

            expect(result.flag).toBe expected

