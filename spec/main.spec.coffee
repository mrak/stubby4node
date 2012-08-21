sut = null
CLI = require '../src/cli'

describe 'main', ->
   beforeEach ->
      sut = require '../src/main'

   describe 'start', ->
      it 'should treat the callback as optional', ->
         callback = jasmine.createSpy 'callback'
         sut.start()
         sut.start {}, callback

         expect(callback.callCount).toBe 1

      it 'should take one parameter as a function', ->
         callback = jasmine.createSpy 'callback'
         sut.start callback
         expect(callback).toHaveBeenCalled()

      describe 'options', ->
         it 'should default stub port to CLI port default', ->
            options = {}
            sut.start options

            expect(options.stub).toEqual CLI.defaults.stub

         it 'should default admin port to CLI port default', ->
            options = {}
            sut.start options

            expect(options.admin).toEqual CLI.defaults.admin

         it 'should default location to CLI port default', ->
            options = {}
            sut.start options

            expect(options.location).toEqual CLI.defaults.location
