sut = null
CLI = require '../src/cli'
global.TESTING = {}
server = null

describe 'main', ->
   beforeEach ->
      server =
         listen: ->
         close: ->
         address: ->

      global.TESTING.http =
         createServer: -> server
      sut = require '../src/main'

   describe 'start', ->
      describe 'options', ->
         it 'should treat the callback as optional', ->
            callback = jasmine.createSpy 'callback'
            sut.start {}, callback

            waitsFor (-> callback.callCount is 1), 'callback to have been called', 1

         it 'should take one parameter as a function', ->
            callback = jasmine.createSpy 'callback'
            sut.start callback

            waitsFor (-> callback.callCount is 1), 'callback to have been called', 1

      describe 'options', ->
         it 'should default stub port to CLI port default', ->
            options = {}
            sut.start options

            waitsFor (-> options.stub is CLI.defaults.stub), 'option stub to be set', 1

         it 'should default admin port to CLI port default', ->
            options = {}
            sut.start options

            waitsFor (-> options.admin is CLI.defaults.admin), 'option admin to be set', 1

         it 'should default location to CLI port default', ->
            options = {}
            sut.start options

            waitsFor (-> options.location is CLI.defaults.location), 'option location to be set', 1
