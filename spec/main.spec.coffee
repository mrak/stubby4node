sut = null
CLI = require '../src/cli'

describe 'main', ->
   beforeEach ->
      sut = require '../src/main'

   describe 'start', ->
      it 'should call stop', ->
         spyOn sut, 'stop'

         sut.start()

         waitsFor (->sut.stop.callCount), 'stop to have been called', 10

      it 'should treat the callback as optional', ->
         callback = jasmine.createSpy 'callback'
         sut.start {}, callback

         waitsFor (-> callback.callCount is 1), 'callback to have been called', 10

      it 'should take one parameter as a function', ->
         callback = jasmine.createSpy 'callback'
         sut.start callback

         waitsFor (-> callback.callCount is 1), 'callback to have been called', 10

      describe 'options', ->
         it 'should default stub port to CLI port default', ->
            options = {}
            sut.start options

            waitsFor (-> options.stub is CLI.defaults.stub), 'option stub to be set', 10

         it 'should default admin port to CLI port default', ->
            options = {}
            sut.start options

            waitsFor (-> options.admin is CLI.defaults.admin), 'option admin to be set', 10

         it 'should default location to CLI port default', ->
            options = {}
            sut.start options

            waitsFor (-> options.location is CLI.defaults.location), 'option location to be set', 10
